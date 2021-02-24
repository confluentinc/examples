#!/bin/bash

#################################################################
# Initialization
#################################################################
NAME=`basename "$0"`

# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

ccloud::validate_version_ccloud_cli $CCLOUD_MIN_VERSION \
  && print_pass "ccloud version ok" \
  || exit 1
ccloud::validate_logged_in_ccloud_cli \
  && print_pass "logged into ccloud CLI" \
  || exit 1
check_python \
  && print_pass "python installed" \
  || exit 1

# Source demo-specific configurations
source config/demo.cfg

ccloud::validate_cloud_source config/demo.cfg \
  && print_pass "cloud source $DATA_SOURCE ok" \
  || exit 1
ccloud::validate_cloud_storage config/demo.cfg \
  && print_pass "cloud storage $DESTINATION_STORAGE ok" \
  || exit 1

export EXAMPLE="cloud-etl"

echo
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
ccloud::generate_configs $CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta
printf "\n"

# Pre-flight check of Confluent Cloud credentials specified in $CONFIG_FILE
MAX_WAIT=720
echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud ksqlDB cluster to be UP"
retry $MAX_WAIT ccloud::validate_ccloud_ksqldb_endpoint_ready $KSQLDB_ENDPOINT || exit 1
ccloud::validate_ccloud_stack_up $CLOUD_KEY $CONFIG_FILE || exit 1

# Set Kafka cluster
ccloud::set_kafka_cluster_use_from_api_key $CLOUD_KEY || exit 1

#################################################################
# Source: create and populate source endpoints
#################################################################
echo -e "\nSource: setup $DATA_SOURCE and populate data\n"
ccloud::create_acls_connector $SERVICE_ACCOUNT_ID
./create_${DATA_SOURCE}.sh || exit 1

#################################################################
# Create input topic and create source connector
#################################################################
ccloud kafka topic create $KAFKA_TOPIC_NAME_IN
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile $AWS_PROFILE)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile $AWS_PROFILE)
if [[ "${DATA_SOURCE}" == "rds" ]]; then
  export CONNECTION_HOST=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].Endpoint.Address")
  export CONNECTION_PORT=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --profile $AWS_PROFILE | jq -r ".DBInstances[0].Endpoint.Port")
fi
ccloud::create_connector connectors/${DATA_SOURCE}.json || exit 1
ccloud::wait_for_connector_up connectors/${DATA_SOURCE}.json 240 || exit 1

#################################################################
# Confluent Cloud ksqlDB application
#################################################################
./create_ksqldb_app.sh || exit 1

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
./read-data.sh $CONFIG_FILE

printf "\nDONE! Connect to your Confluent Cloud UI at https://confluent.cloud/\n"
echo
echo "Local client configuration file written to $CONFIG_FILE"
echo
echo "Cloud resources are provisioned and accruing charges. To destroy this demo and associated resources run ->"
echo "    ./stop.sh $CONFIG_FILE"
echo
