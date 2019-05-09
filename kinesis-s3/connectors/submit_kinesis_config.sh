#!/bin/bash

source ../config/demo.cfg

CONNECT_HOST=localhost

if [[ $1 ]];then
    CONNECT_HOST=$1
fi

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "kinesis-source",
  "config": {
    "name": "kinesis-source",
    "connector.class": "io.confluent.connect.kinesis.KinesisSourceConnector",
    "tasks.max": "1",
    "kafka.topic": "$KAFKA_TOPIC_NAME",
    "kinesis.region": "$DEMO_REGION_UC",
    "kinesis.stream": "$KINESIS_STREAM_NAME",
    "confluent.topic.bootstrap.servers": "localhost:9092",
    "confluent.topic.replication.factor": "1",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "producer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor"
  }
}
EOF
)

echo "curl -X POST -H \"${HEADER}\" --data \"${DATA}\" http://${CONNECT_HOST}:8083/connectors"
curl -X POST -H "${HEADER}" --data "${DATA}" http://${CONNECT_HOST}:8083/connectors
if [[ $? != 0 ]]; then
  echo "ERROR: Could not successfully submit connector. Please troubleshoot Connect."
  exit $?
fi
