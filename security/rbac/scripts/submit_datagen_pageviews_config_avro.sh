#!/bin/bash

source ../config/local-demo.env

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "datagen-pageviews",
  "config": {
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "kafka.topic": "pageviews",
    "quickstart": "pageviews",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "http://localhost:8081",
    "value.converter.basic.auth.credentials.source": "USER_INFO",
    "value.converter.basic.auth.user.info": "${USER_CONNECTOR}:${USER_CONNECTOR}1",
    "max.interval": 100,
    "producer.override.sasl.jaas.config": "org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required username=\"${USER_CONNECTOR}\" password=\"${USER_CONNECTOR}1\" metadataServerUrls=\"http://localhost:8090\";",
    "tasks.max": "1"
  }
}
EOF
)

echo "curl -X POST -H \"${HEADER}\" -u ${USER_CONNECTOR_SUBMITTER}:${USER_CONNECTOR_SUBMITTER}1 --data \"${DATA}\" http://localhost:8083/connectors"
curl -X POST -H "${HEADER}" -u ${USER_CONNECTOR_SUBMITTER}:${USER_CONNECTOR_SUBMITTER}1 --data "${DATA}" http://localhost:8083/connectors
if [[ $? != 0 ]]; then
  echo "ERROR: Could not successfully submit connector. Please troubleshoot Connect."
  exit $?
fi
