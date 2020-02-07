#!/bin/bash

# Source demo-specific configurations
source config/demo.cfg

#################################################################
# Source: create and populate Kinesis streams and create connectors
#################################################################
echo -e "\nSource: create and populate Kinesis streams and create connectors\n"
source $AWS_CREDENTIALS_FILE
echo "aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1 --region $KINESIS_REGION"
aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1 --region $KINESIS_REGION
if [[ $? != 0 ]]; then
  echo "ERROR: Received a non-zero exit code when trying to create the AWS Kinesis stream. Please troubleshoot"
  exit $?
fi
echo -e "\nSleeping 60 seconds waiting for Kinesis stream to be created\n"
sleep 60
#aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION
# File has ~500 records, so run several times to fulfill the flush size requirement of 1000 records / partition for the sink connectors
echo -e "Writing ~11k records to Kinesis\n"
for i in {1..22}; do
  aws kinesis put-records --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION --records file://../utils/table.locations.cloud.json >/dev/null
  if [[ $? != 0 ]]; then
    echo "ERROR: Received a non-zero exit code when trying to put-records into the AWS Kinesis stream. Please troubleshoot"
    exit $?
  fi
done
echo -e "\nSleeping 10 seconds\n"
sleep 10
