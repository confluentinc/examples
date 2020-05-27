#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
. ../utils/helper.sh

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

if [[ $(get_aws_cli_version) -eq 2 ]]; then
  V2_OPTS="--cli-binary-format raw-in-base64-out"
fi
#aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION
# File has ~500 records, so run several times to fulfill the flush size requirement of 1000 records / partition for the sink connectors
echo -e "Writing ~11k records to Kinesis\n"
for i in {1..22}; do
  aws kinesis put-records --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION --records file://./eventLogs.json --profile $AWS_PROFILE $V2_OPTS >/dev/null
  if [[ $? != 0 ]]; then
    echo "ERROR: Received a non-zero exit code when trying to put-records into the AWS Kinesis stream. Please troubleshoot"
    exit 1
  fi
done
echo -e "\nSleeping 5 seconds\n"
sleep 5

exit 0
