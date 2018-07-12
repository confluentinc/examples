#!/bin/sh

curl -X "POST" "http://localhost:18083/connectors/" \
     -H "Content-Type: application/json" \
     -d '{
  "name": "es_sink_LOGON_ENRICHED",
  "config": {
    "topics": "LOGON_ENRICHED",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
    "key.ignore": "true",
    "schema.ignore": "false",
    "type.name": "type.name=kafkaconnect",
    "topic.index.map": "LOGON_ENRICHED:'logon_enriched'",
    "transforms": "ExtractTimestamp",
    "transforms.ExtractTimestamp.type": "org.apache.kafka.connect.transforms.InsertField$Value",
    "transforms.ExtractTimestamp.timestamp.field" : "EXTRACT_TS",
    "connection.url": "http://elasticsearch:9200"
  }
}'

curl -X "POST" "http://localhost:18083/connectors/" \
     -H "Content-Type: application/json" \
     -d '{
  "name": "es_sink_ora-soe-ORDERS",
  "config": {
    "topics": "ora-soe-ORDERS",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
    "key.ignore": "true",
    "schema.ignore": "false",
    "type.name": "type.name=kafkaconnect",
    "topic.index.map": "ora-soe-ORDERS:'orders'",
    "transforms": "ExtractTimestamp",
    "transforms.ExtractTimestamp.type": "org.apache.kafka.connect.transforms.InsertField$Value",
    "transforms.ExtractTimestamp.timestamp.field" : "EXTRACT_TS",
    "connection.url": "http://elasticsearch:9200"
  }
}'

