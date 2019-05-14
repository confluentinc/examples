#!/bin/bash

source ./config/demo.cfg
source ./delta_configs/env.delta

CONNECT_HOST=localhost

if [[ $1 ]];then
    CONNECT_HOST=$1
fi

# CC-4652: Kinesis connector uses enum names
KINESIS_REGION_UC=$(echo "$KINESIS_REGION" | tr '[:lower:]' '[:upper:]' | sed 's/-/_/g')

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "kinesis-source",
  "config": {
    "name": "kinesis-source",
    "connector.class": "io.confluent.connect.kinesis.KinesisSourceConnector",
    "tasks.max": "1",
    "kafka.topic": "$KAFKA_TOPIC_NAME_IN",
    "kinesis.region": "$KINESIS_REGION_UC",
    "kinesis.stream": "$KINESIS_STREAM_NAME",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "confluent.topic.replication.factor": "3",
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
