#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
. ../utils/helper.sh

# Source demo-specific configurations
source config/demo.cfg

check_env || exit 1
check_running_cp ${CP_VERSION_MAJOR} || exit

CONFIG_FILE=~/.ccloud/config
check_ccloud_config $CONFIG_FILE || exit
check_ccloud_logged_in || exit

validate_cloud_storage $DESTINATION_STORAGE || exit

./stop.sh

#################################################################
# Generate CCloud configurations
#################################################################
../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

# Set Kafka cluster
ccloud kafka cluster use $(ccloud api-key list | grep "$CLOUD_KEY" | awk '{print $7;}')

#################################################################
# Source: create and populate Kinesis streams and create connectors
#################################################################
echo -e "\nSource: create and populate Kinesis streams and create connectors\n"
source $AWS_CREDENTIALS_FILE
./create_kinesis_streams.sh

# Create input topic and create source connector
ccloud kafka topic create $KAFKA_TOPIC_NAME_IN
create_connector_cloud connectors/kinesis.json || exit 1

echo -e "\nSleeping 60 seconds waiting for connector to be in RUNNING state\n"
sleep 60

#################################################################
# Confluent Cloud KSQL application
#################################################################
./create_ksql_app.sh

#################################################################
# Sink: setup cloud storage and create connectors
#################################################################
echo -e "\nSink: setup $DESTINATION_STORAGE cloud storage and create connectors\n"

if [[ "$DESTINATION_STORAGE" == "s3" ]]; then

  # Setup S3 bucket
  aws s3api head-bucket --bucket "STORAGE_BUCKET_NAME" --region $STORAGE_REGION 2>/dev/null
  if [[ $? != 0 ]]; then
    echo "aws s3api create-bucket --bucket $STORAGE_BUCKET_NAME --region $STORAGE_REGION --create-bucket-configuration LocationConstraint=$STORAGE_REGION"
    aws s3api create-bucket --bucket $STORAGE_BUCKET_NAME --region $STORAGE_REGION --create-bucket-configuration LocationConstraint=$STORAGE_REGION
  fi

  create_connector_cloud connectors/s3_no_avro.json || exit 1
  create_connector_cloud connectors/s3_avro.json || exit 1

elif [[ "$DESTINATION_STORAGE" == "gcs" ]]; then

  # Setup GCS
  bucket_list=$(gsutil ls | grep $STORAGE_BUCKET_NAME)
  if [[ ! "$bucket_list" =~ "$STORAGE_BUCKET_NAME" ]]; then
    echo "gsutil mb -l $STORAGE_REGION gs://$STORAGE_BUCKET_NAME"
    gsutil mb -l $STORAGE_REGION gs://$STORAGE_BUCKET_NAME
  fi

  create_connector_cloud connectors/gcs_no_avro.json || exit 1
  create_connector_cloud connectors/gcs_avro.json || exit 1

else

  # Setup Azure container
  source $STORAGE_CREDENTIALS_FILE
  az storage container show --name $STORAGE_BUCKET_NAME --account-name $AZBLOB_ACCOUNT_NAME
  if [[ $? != 0 ]]; then
    echo "az storage container create --name $STORAGE_BUCKET_NAME --account-name $AZBLOB_ACCOUNT_NAME"
    az storage container create --name $STORAGE_BUCKET_NAME --account-name $AZBLOB_ACCOUNT_NAME
  fi

  create_connector_cloud connectors/az_no_avro.json || exit 1

  # While Azure Blob Sink is in Preview, limit is only one connector of this type
  # So these lines are to remain commented out until then
  #create_connector_cloud connectors/az_avro.json || exit 1

fi

echo -e "\nSleeping 60 seconds waiting for connector to be in RUNNING state\n"
sleep 60

#################################################################
# Validation: Read Data
#################################################################
echo -e "\nSleeping 60 seconds waiting for data to be sent to $DESTINATION_STORAGE\n"
sleep 60
./read-data.sh

echo -e "\nDONE!\n"
