#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
. ../utils/helper.sh

# Source demo-specific configurations
source config/demo.cfg

check_ccloud_config $CONFIG_FILE || exit 1
check_ccloud_version 0.234.0 || exit 1
check_ccloud_logged_in || exit 1

validate_cloud_storage config/demo.cfg || exit 1

./stop.sh || exit 1

#################################################################
# Generate CCloud configurations
#################################################################
../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

# Set Kafka cluster
if [[ "$CLOUD_KEY" == "" ]]; then
  echo "ERROR: could not parse the broker credentials from $CONFIG_FILE. Verify your credentials and try again."
  exit 1
fi
kafkaCluster=$(ccloud api-key list | grep "$CLOUD_KEY" | awk '{print $8;}')
if [[ "$kafkaCluster" == "" ]]; then
  echo "ERROR: Could not associate key $CLOUD_KEY to a Confluent Cloud Kafka cluster. Verify your credentials, ensure the API key has a set resource type, and try again."
  exit 1
fi
ccloud kafka cluster use $kafkaCluster
echo -e "\nAssociated key $CLOUD_KEY to Confluent Cloud Kafka cluster $kafkaCluster:\n"
ccloud kafka cluster describe $kafkaCluster

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

echo -e "\nSleeping 60 seconds waiting for connector to be in RUNNING state\n"
sleep 60

#################################################################
# Confluent Cloud KSQL application
#################################################################
./create_ksql_app.sh || exit 1

#################################################################
# Sink: setup cloud storage and create connectors
#################################################################
echo -e "\nSink: setup $DESTINATION_STORAGE cloud storage and create connectors\n"
./setup_storage_${DESTINATION_STORAGE}.sh || exit 1
echo -e "\nSleeping 60 seconds waiting for connector to be in RUNNING state\n"
sleep 60

#################################################################
# Validation: Read Data
#################################################################
echo -e "\nSleeping 60 seconds waiting for data to be sent to $DESTINATION_STORAGE\n"
sleep 60
./read-data.sh

echo -e "\nDONE!\n"
