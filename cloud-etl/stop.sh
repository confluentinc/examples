#!/bin/bash

# Source library 
. ../utils/helper.sh

# Source demo-specific configurations
source config/demo.cfg

# Clean up AWS Kinesis and cloud storage
echo "Clean up AWS Kinesis"
aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION --profile $AWS_PROFILE > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  aws kinesis delete-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION --profile $AWS_PROFILE
fi
echo "Clean up $DESTINATION_STORAGE cloud storage"
if [[ "$DESTINATION_STORAGE" == "s3" ]]; then
  aws s3 rm --recursive s3://$S3_BUCKET/topics/${KAFKA_TOPIC_NAME_OUT1} --region $STORAGE_REGION --profile $S3_PROFILE
  aws s3 rm --recursive s3://$S3_BUCKET/topics/${KAFKA_TOPIC_NAME_OUT2} --region $STORAGE_REGION --profile $S3_PROFILE
elif [[ "$DESTINATION_STORAGE" == "gcs" ]]; then
  check_gsutil || exit 1
  # Clean up GCS
  gsutil -m rm -r gs://$GCS_BUCKET/**
else
  export AZBLOB_ACCOUNT_KEY=$(az storage account keys list --account-name $AZBLOB_STORAGE_ACCOUNT | jq -r '.[0].value')
  az storage blob delete-batch --source $AZBLOB_CONTAINER --account-name $AZBLOB_STORAGE_ACCOUNT --account-key $AZBLOB_ACCOUNT_KEY --pattern "topics/${KAFKA_TOPIC_NAME_OUT1}/*"
  az storage blob delete-batch --source $AZBLOB_CONTAINER --account-name $AZBLOB_STORAGE_ACCOUNT --account-key $AZBLOB_ACCOUNT_KEY --pattern "topics/${KAFKA_TOPIC_NAME_OUT2}/*"
fi

# Destroy Confluent Cloud resources
if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './start.sh'. (Is it in stack-configs/ folder?) "
  exit 1
else
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
  CONFIG_FILE=${DIR}/$1
  ../ccloud/ccloud-stack/ccloud_stack_destroy.sh $CONFIG_FILE
fi
