#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

# Source demo-specific configurations
source config/demo.cfg

#################################################################
# Source: create and populate Kinesis streams and create connectors
#################################################################
echo "aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1 --region $KINESIS_REGION --profile $AWS_PROFILE"
aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1 --region $KINESIS_REGION --profile $AWS_PROFILE
if [[ $? != 0 ]]; then
  echo "ERROR: Received a non-zero exit code when trying to create the AWS Kinesis stream. Please troubleshoot"
  exit 1
fi
echo -e "\nSleeping 60 seconds waiting for Kinesis stream to be created\n"
sleep 60

./add_entries_kinesis.sh

exit 0
