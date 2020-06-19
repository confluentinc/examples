DROP TABLE IF EXISTS customers;
CREATE TABLE customers (id INTEGER KEY NOT NULL, firstName VARCHAR(255), lastName VARCHAR(255), email VARCHAR(255), address VARCHAR(255), level VARCHAR(255));
.separator '|'
.import customers.table customers
