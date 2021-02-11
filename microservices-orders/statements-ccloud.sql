CREATE STREAM orders WITH (kafka_topic='orders', value_format='AVRO');
CREATE TABLE customers_table (customerid bigint PRIMARY KEY, firstname varchar, lastname varchar, email varchar, address varchar, level varchar) WITH (KAFKA_TOPIC='customers', VALUE_FORMAT='AVRO');
CREATE STREAM orders_enriched AS SELECT customers_table.customerid AS customerid, customers_table.firstname, customers_table.lastname, customers_table.level, orders.product, orders.quantity, orders.price FROM orders LEFT JOIN customers_table ON orders.customerid = customers_table.customerid;
CREATE TABLE FRAUD_ORDER WITH (key_format='json') AS SELECT CUSTOMERID, LASTNAME, FIRSTNAME, COUNT(*) AS COUNTS FROM orders_enriched WINDOW TUMBLING (SIZE 30 SECONDS) GROUP BY CUSTOMERID, LASTNAME, FIRSTNAME HAVING COUNT(*)>2;
