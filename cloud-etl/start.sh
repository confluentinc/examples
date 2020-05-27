#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
. ../utils/helper.sh

check_ccloud_version 1.0.0 \
  && print_pass "ccloud version ok" \
  || exit 1
check_ccloud_logged_in \
  && print_pass "logged into ccloud CLI" \
  || exit 1
check_python \
  && print_pass "python installed" \
  || exit 1

# Source demo-specific configurations
source config/demo.cfg

validate_cloud_storage config/demo.cfg \
  && print_pass "cloud storage validated" \
  || exit 1

echo ====== Create new Confluent Cloud stack
prompt_continue_cloud_demo || exit 1
cloud_create_demo_stack true
SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
if [[ "$SERVICE_ACCOUNT_ID" == "" ]]; then
  echo "ERROR: Could not determine SERVICE_ACCOUNT_ID from 'ccloud kafka cluster list'. Please troubleshoot, destroy stack, and try again to create the stack."
  exit 1
fi
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
export CONFIG_FILE=$CONFIG_FILE
check_ccloud_config $CONFIG_FILE \
  && print_pass "$CONFIG_FILE ok" \
  || exit 1

echo ====== Generate CCloud configurations
../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta
printf "\n"

# Pre-flight check of Confluent Cloud credentials specified in $CONFIG_FILE
MAX_WAIT=720
echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud KSQL cluster to be UP"
retry $MAX_WAIT check_ccloud_ksql_endpoint_ready $KSQL_ENDPOINT || exit 1
ccloud_demo_preflight_check $CLOUD_KEY $CONFIG_FILE || exit 1

# Set Kafka cluster
ccloud_cli_set_kafka_cluster_use $CLOUD_KEY $CONFIG_FILE || exit 1

#################################################################
# Source: create and populate Kinesis streams and create connectors
#################################################################
echo -e "\nSource: create and populate Kinesis streams and create connectors\n"
./create_kinesis_streams.sh || exit 1

# Create input topic and create source connector
ccloud kafka topic create $KAFKA_TOPIC_NAME_IN
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile $AWS_PROFILE)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile $AWS_PROFILE)
create_connector_cloud connectors/kinesis.json || exit 1
wait_for_connector_up connectors/kinesis.json 240 || exit 1

#################################################################
# Confluent Cloud KSQL application
#################################################################
./create_ksql_app.sh || exit 1

#################################################################
# Sink: setup cloud storage and create connectors
#################################################################
echo -e "\nSink: setup $DESTINATION_STORAGE cloud storage and create connectors\n"
./setup_storage_${DESTINATION_STORAGE}.sh || exit 1

#################################################################
# Validation: Read Data
#################################################################
echo -e "\nSleeping 60 seconds waiting for data to be sent to $DESTINATION_STORAGE\n"
sleep 60
./read-data.sh

printf "\nDONE! Connect to your Confluent Cloud UI at https://confluent.cloud/ or Confluent Control Center at http://localhost:9021\n"
echo
echo "Local client configuration file written to $CONFIG_FILE"
echo
