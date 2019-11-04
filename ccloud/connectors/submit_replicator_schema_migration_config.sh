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
    "topic.whitelist": "_schemas",
    "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "schema.registry.topic": "_schemas",
    "schema.registry.url": "$SCHEMA_REGISTRY_URL",
    "schema.registry.client.basic.auth.credentials.source": "$BASIC_AUTH_CREDENTIALS_SOURCE",
    "schema.registry.client.basic.auth.user.info": "$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO",
    "dest.kafka.bootstrap.servers": "$BOOTSTRAP_SERVERS",
    "dest.kafka.security.protocol": "SASL_SSL",
    "dest.kafka.sasl.mechanism": "PLAIN",
    "dest.kafka.sasl.jaas.config": "$REPLICATOR_SASL_JAAS_CONFIG",
    "confluent.topic.replication.factor": 3,
    "src.kafka.bootstrap.servers": "localhost:9092",
    "src.consumer.group.id": "connect-replicator-migrate-schemas",
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
