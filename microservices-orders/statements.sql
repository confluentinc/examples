CREATE STREAM orders WITH (kafka_topic='orders', value_format='AVRO');

--Next 3 steps are required to create a TABLE with keys of String type

--1. Create a stream
CREATE STREAM customers_with_wrong_format_key WITH (kafka_topic='customers', value_format='AVRO');

--2. Derive a new stream with the required key changes.
--The CAST statement converts the key to the required format.
--The PARTITION BY clause re-partitions the stream based on the new, converted key.
CREATE STREAM customers_with_proper_key WITH (KAFKA_TOPIC='customers-with-proper-key') AS SELECT CAST(id as BIGINT) as customerid, firstname, lastname, email, address, level FROM customers_with_wrong_format_key PARTITION BY CAST(id as BIGINT);

--3. Create the table on the properly keyed stream
CREATE TABLE customers_table (rowkey bigint KEY, customerid bigint, firstname varchar, lastname varchar, email varchar, address varchar, level varchar) WITH (KAFKA_TOPIC='customers-with-proper-key', VALUE_FORMAT='AVRO', KEY='customerid');

--Join customer information based on customer id
CREATE STREAM orders_cust1_joined AS SELECT customers_table.customerid AS customerid, firstname, lastname, state, product, quantity, price FROM orders LEFT JOIN customers_table ON orders.customerid = customers_table.customerid;

--Fraud alert if a customer submits more than 2 orders in a 30 second time window
CREATE TABLE FRAUD_ORDER AS SELECT CUSTOMERID, LASTNAME, FIRSTNAME, COUNT(*) AS COUNTS FROM orders_cust1_joined WINDOW TUMBLING (SIZE 30 SECONDS) GROUP BY CUSTOMERID, LASTNAME, FIRSTNAME HAVING COUNT(*)>2;
