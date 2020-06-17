#!/bin/bash

TABLE="customers"
TABLE_PATH="customers.table"
DB=data/microservices.db

echo "DROP TABLE IF EXISTS $TABLE;" | sqlite3 $DB
echo "CREATE TABLE $TABLE(id INTEGER KEY NOT NULL, firstName VARCHAR(255), lastName VARCHAR(255), email VARCHAR(255), address VARCHAR(255), level VARCHAR(255));" | sqlite3 $DB
echo ".import $TABLE_PATH $TABLE" | sqlite3 $DB

