--We need to identify fields in schema, even with Avro, because this is a script (https://github.com/confluentinc/ksql/issues/1031)
CREATE STREAM JDBCAVROKSQLLOCATIONS (id bigint, name varchar, sale bigint) with (kafka_topic='jdbcavroksql-locations', value_format='AVRO');

--Add key using `PARTITION BY`
CREATE STREAM JDBCAVROKSQLLOCATIONSWITHKEY AS SELECT * FROM JDBCAVROKSQLLOCATIONS PARTITION BY ID;

--COUNT
CREATE TABLE COUNTLOCATIONS AS SELECT id, COUNT(*) FROM JDBCAVROKSQLLOCATIONSWITHKEY GROUP BY id;

--SUM
CREATE TABLE SUMLOCATIONS AS SELECT id, SUM(sale) FROM JDBCAVROKSQLLOCATIONSWITHKEY GROUP BY id;

