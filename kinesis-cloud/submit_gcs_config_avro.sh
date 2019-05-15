#!/bin/bash

source ./config/demo.cfg
source ./delta_configs/env.delta


CONNECT_HOST=localhost

if [[ $1 ]];then
    CONNECT_HOST=$1
fi

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "gcs-sink-avro",
  "config": {
    "name": "gcs-sink-avro",
    "connector.class": "io.confluent.connect.gcs.GcsSinkConnector",
    "tasks.max": "1",
    "gcs.bucket.name": "$STORAGE_BUCKET_NAME",
    "gcs.part.size": "5242880",
    "flush.size": "3",
    "storage.class": "io.confluent.connect.gcs.storage.GcsStorage",
    "format.class": "io.confluent.connect.gcs.format.avro.AvroFormat",
    "partitioner.class": "io.confluent.connect.storage.partitioner.DefaultPartitioner",
    "schema.compatibility": "NONE",
    "topics": "$KAFKA_TOPIC_NAME_OUT",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.basic.auth.credentials.source": "$BASIC_AUTH_CREDENTIALS_SOURCE",
    "value.converter.schema.registry.basic.auth.user.info": "$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO",
    "value.converter.schema.registry.url": "$SCHEMA_REGISTRY_URL",
    "confluent.topic.bootstrap.servers": "$BOOTSTRAP_SERVERS",
    "confluent.topic.security.protocol": "SASL_SSL",
    "confluent.topic.sasl.mechanism": "PLAIN",
    "confluent.topic.sasl.jaas.config": "$REPLICATOR_SASL_JAAS_CONFIG",
    "producer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor"
  }
}
EOF
)

echo "curl -X POST -H \"${HEADER}\" --data \"${DATA}\" http://${CONNECT_HOST}:8087/connectors"
curl -X POST -H "${HEADER}" --data "${DATA}" http://${CONNECT_HOST}:8087/connectors
if [[ $? != 0 ]]; then
  echo "ERROR: Could not successfully submit connector. Please troubleshoot Connect."
  exit $?
fi
