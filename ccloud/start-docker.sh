#!/bin/bash

# Source library
. ../utils/helper.sh

check_ccloud || exit
check_jq || exit

USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY=false
if [[ "$USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY" == true ]]; then
  SCHEMA_REGISTRY_CONFIG_FILE=$HOME/.ccloud/config
else
  SCHEMA_REGISTRY_CONFIG_FILE=schema_registry_docker.config
fi
./ccloud-generate-cp-configs.sh $SCHEMA_REGISTRY_CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

if [[ "$USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY" == true ]]; then
  validate_confluent_cloud_schema_registry $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL || exit 1
fi

ccloud topic create users
ccloud topic create pageviews

docker-compose up -d --build

if [[ $USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY == true ]]; then
  docker-compose kill schema-registry
fi

echo "Sleeping 120 seconds to wait for all services to come up"
sleep 120

# Reregister a schema for a topic with a different name
#curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{\"schema\": $(curl -s http://localhost:8085/subjects/pageviews-value/versions/latest | jq '.schema')}" http://localhost:8085/subjects/pageviews.replica-value/versions 

# kafka-connect-datagen
./submit_datagen_users_config.sh
./submit_datagen_pageviews_config.sh

# Replicator
./submit_replicator_docker_config.sh

sleep 30

docker-compose exec ksql-cli bash -c "ksql http://ksql-server:8089 <<EOF
run script '/tmp/ksql.commands';
exit ;
EOF
"
