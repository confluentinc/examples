#!/bin/bash

# Source library
. ../utils/helper.sh

check_jq || exit

. ./config.sh
check_ccloud_config $CONFIG_FILE || exit

if [[ "${USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY}" == true ]]; then
  SCHEMA_REGISTRY_CONFIG_FILE=$HOME/.ccloud/config
else
  SCHEMA_REGISTRY_CONFIG_FILE=schema_registry_docker.config
fi
./ccloud-generate-cp-configs.sh $CONFIG_FILE $SCHEMA_REGISTRY_CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

if [[ "$USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY" == true ]]; then
  validate_confluent_cloud_schema_registry $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL || exit 1
fi

docker-compose up -d

if [[ "${USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY}" == true ]]; then
  echo "Killing the local schema-registry Docker container to use Confluent Cloud Schema Registry instead"
  docker-compose kill schema-registry
fi
if [[ "${USE_CONFLUENT_CLOUD_KSQL}" == true ]]; then
  echo "Killing the local ksql-server Docker container to use Confluent Cloud KSQL instead"
  docker-compose kill ksql-server
fi

echo "Sleeping 120 seconds to wait for all services to come up"
sleep 120

docker-compose exec connect-cloud bash -c 'kafka-topics --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --command-config /tmp/ak-tools-ccloud.delta --topic users --create --replication-factor 3 --partitions 6'
docker-compose exec connect-cloud bash -c 'kafka-topics --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --command-config /tmp/ak-tools-ccloud.delta --topic pageviews --create --replication-factor 3 --partitions 6'

# Reregister a schema for a topic with a different name
#curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{\"schema\": $(curl -s http://localhost:8085/subjects/pageviews-value/versions/latest | jq '.schema')}" http://localhost:8085/subjects/pageviews.replica-value/versions 

# kafka-connect-datagen
. ./connectors/submit_datagen_users_config.sh
. ./connectors/submit_datagen_pageviews_config.sh

# Replicator
. ./connectors/submit_replicator_docker_config.sh

sleep 30

if [[ "${USE_CONFLUENT_CLOUD_KSQL}" == false ]]; then
  docker-compose exec ksql-cli bash -c "ksql http://ksql-server:8089 <<EOF
run script '/tmp/ksql.commands';
exit ;
EOF
"
else
  echo -e "\nSince you are running Confluent Cloud KSQL, use the Cloud UI to copy/paste the KSQL queries from the 'ksql.commands' file\n"
fi
