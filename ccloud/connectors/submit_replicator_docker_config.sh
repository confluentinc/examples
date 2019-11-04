#!/bin/bash

source delta_configs/env.delta

CONNECT_HOST=localhost

if [[ $1 ]];then
    CONNECT_HOST=$1
fi

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "replicator",
  "config": {
    "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
    "topic.whitelist": "pageviews",
    "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "dest.kafka.bootstrap.servers": "$BOOTSTRAP_SERVERS",
    "dest.kafka.security.protocol": "SASL_SSL",
    "dest.kafka.sasl.mechanism": "PLAIN",
    "dest.kafka.sasl.jaas.config": "$REPLICATOR_SASL_JAAS_CONFIG",
    "confluent.topic.replication.factor": 3,
    "src.kafka.bootstrap.servers": "kafka:29092",
    "src.consumer.group.id": "connect-replicator",
    "src.consumer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor",
    "src.consumer.confluent.monitoring.interceptor.bootstrap.servers": "$BOOTSTRAP_SERVERS",
    "src.consumer.confluent.monitoring.interceptor.security.protocol": "SASL_SSL",
    "src.consumer.confluent.monitoring.interceptor.sasl.mechanism": "PLAIN",
    "src.consumer.confluent.monitoring.interceptor.sasl.jaas.config": "$REPLICATOR_SASL_JAAS_CONFIG",
    "src.kafka.timestamps.producer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.bootstrap.servers": "$BOOTSTRAP_SERVERS",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.security.protocol": "SASL_SSL",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.sasl.mechanism": "PLAIN",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.sasl.jaas.config": "$REPLICATOR_SASL_JAAS_CONFIG",
    "tasks.max": "1"
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
