#!/bin/bash

# Source library
. ../utils/helper.sh

check_ccloud || exit
check_jq || exit

./ccloud-generate-cp-configs.sh

source delta_configs/env.delta

USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY=1
SR_PROPERTIES_FILE=delta_configs/confluent-cloud-schema-registry.properties
if [[ $USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY != 1 ]]; then
  export SCHEMA_REGISTRY_URL=http://schema-registry:8085
  unset BASIC_AUTH_CREDENTIALS_SOURCE
  unset SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO
  echo "schema.registry.url=$SCHEMA_REGISTRY_URL" > $SR_PROPERTIES_FILE
else
  validate_confluent_cloud_schema_registry $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL || exit 1
fi

ccloud topic create users
ccloud topic create pageviews

docker-compose up -d --build

if [[ $USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY == 1 ]]; then
  docker-compose kill schema-registry
fi

echo "Sleeping 60 seconds to wait for all services to come up"
sleep 60

#curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{\"schema\": $(curl -s http://localhost:8085/subjects/pageviews-value/versions/latest | jq '.schema')}" http://localhost:8085/subjects/pageviews.replica-value/versions 

./submit_replicator_config.sh
# Use kafka-connect-datagen for 'users' topic instead of ksql-datagen due to KSQL-2278
docker-compose kill ksql-datagen-users
./submit_datagen_users_config.sh

sleep 10

docker-compose exec ksql-cli bash -c "ksql http://ksql-server:8089 <<EOF
run script '/tmp/ksql.commands';
exit ;
EOF
"
