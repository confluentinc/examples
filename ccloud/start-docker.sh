#!/bin/bash

# Source library
source ../utils/helper.sh

echo ====== Verifying prerequisites
ccloud::validate_version_ccloud_cli 1.7.0 \
  && print_pass "ccloud version ok" \
  || exit 1
ccloud::validate_logged_in_ccloud_cli \
  && print_pass "logged into ccloud CLI" \
  || exit 1
check_jq \
  && print_pass "jq installed" \
  || exit 1

echo ====== Create new Confluent Cloud stack
ccloud::prompt_continue_ccloud_demo || exit 1
ccloud::create_ccloud_stack true
SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
if [[ "$SERVICE_ACCOUNT_ID" == "" ]]; then
  echo "ERROR: Could not determine SERVICE_ACCOUNT_ID from 'ccloud kafka cluster list'. Please troubleshoot, destroy stack, and try again to create the stack."
  exit 1
fi
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
export CONFIG_FILE=$CONFIG_FILE
ccloud::validate_ccloud_config $CONFIG_FILE \
  && print_pass "$CONFIG_FILE ok" \
  || exit 1

echo ====== Generate CCloud configurations
./ccloud-generate-cp-configs.sh $CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta
printf "\n"

# Pre-flight check of Confluent Cloud credentials specified in $CONFIG_FILE
MAX_WAIT=720
echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud KSQL cluster to be UP"
retry $MAX_WAIT ccloud::validate_ccloud_ksql_endpoint_ready $KSQL_ENDPOINT || exit 1
ccloud::validate_ccloud_stack_up $CLOUD_KEY $CONFIG_FILE || exit 1

echo ====== Set Kafka cluster and service account
ccloud::set_kafka_cluster_use $CLOUD_KEY $CONFIG_FILE || exit 1
serviceAccount=$(ccloud::get_service_account $CLOUD_KEY $CONFIG_FILE) || exit 1

echo ====== Set ACLs for Confluent Control Center and Kafka Connect
ccloud::create_acls_control_center $serviceAccount
ccloud::create_acls_connect_topics $serviceAccount
printf "\n"

echo ====== Validate credentials to Confluent Cloud Schema Registry
ccloud::validate_schema_registry_up $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL || exit 1
printf "Done\n\n"

echo ====== Creating cloud topics users and pageviews and setting ACLs
# users
ccloud kafka topic create users
ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic users
# pageviews
# No need to pre-create topic pageviews in Confluent Cloud because Replicator will do this automatically
ccloud::create_acls_replicator $serviceAccount pageviews
printf "\n"

echo ====== Starting local services in Docker
docker-compose up -d
printf "\n"

MAX_WAIT=240
echo "Waiting up to $MAX_WAIT seconds for connect-local to start"
retry $MAX_WAIT check_connect_up connect-local || exit 1
echo "Waiting up to $MAX_WAIT seconds for connect-cloud to start"
retry $MAX_WAIT check_connect_up connect-cloud || exit 1
printf "\n\n"

echo ====== Deploying kafka-connect-datagen for users 
source ./connectors/submit_datagen_users_config.sh
printf "\n\n"

echo ====== Deploying kafka-connect-datagen for pageviews
source ./connectors/submit_datagen_pageviews_config.sh
printf "\n\n"

echo ====== Deploying Replicator
source ./connectors/submit_replicator_docker_config.sh
printf "\n\n"

echo ====== Creating Confluent Cloud KSQL application
./create_ksql_app.sh || exit 1

printf "\nDONE! Connect to your Confluent Cloud UI at https://confluent.cloud/ or Confluent Control Center at http://localhost:9021\n"
echo
echo "Local client configuration file written to $CONFIG_FILE"
echo
