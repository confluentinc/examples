#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
. ../utils/helper.sh

# Source demo-specific configurations
source config/demo.cfg

check_ccloud_config $CONFIG_FILE || exit 1
check_ccloud_version 0.239.0 || exit 1
check_ccloud_logged_in || exit 1
check_python || exit 1

validate_cloud_storage config/demo.cfg || exit 1

./stop.sh || exit 1

#################################################################
# Generate CCloud configurations
#################################################################
../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

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

echo -e "\nDONE!\n"
