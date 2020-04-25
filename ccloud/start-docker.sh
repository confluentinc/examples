#!/bin/bash

# Source library
. ../utils/helper.sh

echo ====== Verifying prerequisites
check_jq || exit

# File with Confluent Cloud configuration parameters: example template
#   $ cat ~/.ccloud/config
#   bootstrap.servers=<BROKER ENDPOINT>
#   ssl.endpoint.identification.algorithm=https
#   security.protocol=SASL_SSL
#   sasl.mechanism=PLAIN
#   sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
#   # Confluent Cloud Schema Registry
#   basic.auth.credentials.source=USER_INFO
#   schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
#   schema.registry.url=https://<SR ENDPOINT>
#   # Confluent Cloud KSQL
#   ksql.endpoint=https://<KSQL ENDPOINT>
#   ksql.basic.auth.user.info=<KSQL API KEY>:<KSQL API SECRET>
export CONFIG_FILE=~/.ccloud/config

check_ccloud_config $CONFIG_FILE || exit 1
check_ccloud_version 0.264.0 || exit 1
check_ccloud_logged_in || exit 1
printf "Done\n\n"

echo ====== Cleaning up previous run
./stop-docker.sh
printf "\nDone with cleanup\n\n"

echo ====== Generate CCloud configurations
SCHEMA_REGISTRY_CONFIG_FILE=$HOME/.ccloud/config
./ccloud-generate-cp-configs.sh $CONFIG_FILE $SCHEMA_REGISTRY_CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta
printf "\n"

echo ====== Set Kafka cluster and service account
ccloud_cli_set_kafka_cluster_use $CLOUD_KEY $CONFIG_FILE || exit 1
serviceAccount=$(ccloud_cli_get_service_account $CLOUD_KEY $CONFIG_FILE) || exit 1

echo ====== Set ACLs for Confluent Control Center and Kafka Cnnect
create_c3_acls $serviceAccount
create_connect_topics_and_acls $serviceAccount
printf "\n"

echo ====== Validate credentials to Confluent Cloud Schema Registry
validate_confluent_cloud_schema_registry $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL || exit 1
printf "Done\n\n"

echo ====== Creating cloud topics
ccloud kafka topic create users
ccloud kafka topic create pageviews
printf "\n"

echo ====== Starting local services in Docker
docker-compose up -d
printf "\n"

MAX_WAIT=180
echo "Waiting up to $MAX_WAIT seconds for connect-local to start"
retry $MAX_WAIT check_connect_up connect-local || exit 1
echo "Waiting up to $MAX_WAIT seconds for connect-cloud to start"
retry $MAX_WAIT check_connect_up connect-cloud || exit 1
printf "\n\n"

echo ====== Deploying kafka-connect-datagen for users 
. ./connectors/submit_datagen_users_config.sh
printf "\n\n"

echo ====== Deploying kafka-connect-datagen for pageviews
. ./connectors/submit_datagen_pageviews_config.sh
printf "\n\n"

echo ====== Deploying Replicator
. ./connectors/submit_replicator_docker_config.sh
printf "\n\n"

echo ====== Creating Confluent Cloud KSQL application
./create_ksql_app.sh || exit 1

printf "\nDONE! Connect to your Confluent Cloud UI or Confluent Control Center at http://localhost:9021\n"

