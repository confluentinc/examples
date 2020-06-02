#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

# Source demo-specific configurations
source config/demo.cfg

if [[ $(ccloud::get_version_aws_cli) -eq 2 ]]; then
  V2_OPTS="--cli-binary-format raw-in-base64-out"
fi
#aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION
# File has ~500 records, so run several times to fulfill the flush size requirement of 1000 records / partition for the sink connectors
echo -e "Writing ~11k records to Kinesis\n"
for i in {1..22}; do
  aws kinesis put-records --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION --records file://./$KAFKA_TOPIC_NAME_IN.json --profile $AWS_PROFILE $V2_OPTS >/dev/null
  if [[ $? != 0 ]]; then
    echo "ERROR: Received a non-zero exit code when trying to put-records into the AWS Kinesis stream. Please troubleshoot"
    exit 1
  fi
done
echo -e "\nSleeping 5 seconds\n"
sleep 5

exit 0
