Place the jar into: confluent-3.3.0/share/java/kafka-connect-elasticsearch/
 
 Also configure the properties when adding via REST
 
``` curl -X "POST" "http://localhost:8083/connectors/" \
      -H "Content-Type: application/json" \
      -d $'{
   "name": "es_sink_'$TABLE_NAME'",
   "config": {
     "schema.ignore": "true",
     "topics": "'$TABLE_NAME'",
     "key.converter": "org.apache.kafka.connect.storage.StringConverter",
     "value.converter.schemas.enable": false,
     "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
     "key.ignore": "true",
     "value.converter": "org.apache.kafka.connect.json.JsonConverter",
     "type.name": "type.name=kafkaconnect",
     "topic.index.map": "'$TABLE_NAME':'$table_name'",
      "connection.url": "http://localhost:9200",
     "transforms": "FilterNulls",
     "transforms.FilterNulls.type": "io.confluent.transforms.NullFilter"
   }
 }'
 ```

