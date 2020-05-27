CREATE STREAM eventlogs (eventSourceIP varchar, eventAction varchar, Result varchar, eventDuration bigint) WITH (kafka_topic='eventlogs', value_format='JSON');
CREATE TABLE count_per_source WITH (KAFKA_TOPIC='COUNT_PER_SOURCE', PARTITIONS=6) AS SELECT eventSourceIP, count(*) as COUNT FROM eventlogs GROUP BY eventSourceIP EMIT CHANGES;
CREATE TABLE sum_per_source WITH (KAFKA_TOPIC='SUM_PER_SOURCE', PARTITIONS=6, VALUE_FORMAT='AVRO') AS SELECT eventSourceIP, sum(eventDuration) as SUM FROM eventlogs WHERE Result='Pass' GROUP BY eventSourceIP EMIT CHANGES;
