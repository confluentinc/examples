#!/bin/sh

curl -X "POST" "http://localhost:18083/connectors/" \
     -H "Content-Type: application/json" \
     -d '{
             "name": "jdbc_sink_postgres",
             "config": {
                 "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
                 "connection.url": "jdbc:postgresql://postgres:5432/postgres?user=postgres&password=postgres",
                 "auto.create":"true",
                 "auto.evolve":"true",
                 "topics": "RATINGS_WITH_CUSTOMER_DATA",
                 "key.converter": "org.apache.kafka.connect.storage.StringConverter",
                 "transforms": "ExtractTimestamp",
                 "transforms.ExtractTimestamp.type": "org.apache.kafka.connect.transforms.InsertField$Value",
                 "transforms.ExtractTimestamp.timestamp.field" : "EXTRACT_TS"
             }
     }'
