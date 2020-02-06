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

if [[ "$DESTINATION_STORAGE" == "s3" ]]; then
  check_aws || exit
else
  check_gcp_creds || exit
  check_gsutil || exit
fi

./stop.sh

#################################################################
# Generate CCloud configurations
#################################################################
../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

#################################################################
# Source: create and populate Kinesis streams and create connectors
#################################################################
source $AWS_CREDENTIALS_FILE
echo "aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1 --region $KINESIS_REGION"
aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1 --region $KINESIS_REGION
if [[ $? != 0 ]]; then
  echo "ERROR: Received a non-zero exit code when trying to create the AWS Kinesis stream. Please troubleshoot"
  exit $?
fi
echo -e "\nSleeping 60 seconds waiting for Kinesis stream to be created\n"
sleep 60
aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION
aws kinesis put-records --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION --records file://../utils/table.locations.cloud.json
aws kinesis put-records --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION --records file://../utils/table.locations.cloud.json
aws kinesis put-records --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION --records file://../utils/table.locations.cloud.json
echo -e "\nSleeping 10 seconds\n"
sleep 10

# Create topics and create source connector
ccloud kafka cluster use $(ccloud api-key list | grep "$CLOUD_KEY" | awk '{print $7;}')
ccloud kafka topic create $KAFKA_TOPIC_NAME_IN
ccloud connector create -vvv --config <(eval "cat <<EOF
$(<connector_config_kinesis.json)
EOF
")
if [[ $? != 0 ]]; then echo "Exit status was not 0.  Please troubleshoot and try again"; exit 1 ; fi
echo -e "\nSleeping 60 seconds waiting for connector to be in RUNNING state\n"
sleep 60

#################################################################
# Confluent Cloud KSQL application
#################################################################
validate_ccloud_ksql $KSQL_ENDPOINT || exit 1

# Create required topics and ACLs
ccloud kafka topic create $KAFKA_TOPIC_NAME_OUT1
ccloud kafka topic create $KAFKA_TOPIC_NAME_OUT2
ksqlAppId=$(ccloud ksql app list | grep "$KSQL_ENDPOINT" | awk '{print $1}')
ccloud ksql app configure-acls $ksqlAppId $KAFKA_TOPIC_NAME_IN $KAFKA_TOPIC_NAME_OUT1 $KAFKA_TOPIC_NAME_OUT2
ccloud kafka acl create --allow --service-account-id $(ccloud service-account list | grep $ksqlAppId | awk '{print $1;}') --operation WRITE --topic $KAFKA_TOPIC_NAME_OUT1
ccloud kafka acl create --allow --service-account-id $(ccloud service-account list | grep $ksqlAppId | awk '{print $1;}') --operation WRITE --topic $KAFKA_TOPIC_NAME_OUT2

# Submit KSQL queries
while read ksqlCmd; do
  echo -e "\n$ksqlCmd\n"
  curl -X POST $KSQL_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQL_BASIC_AUTH_USER_INFO \
       -d @<(cat <<EOF
{
  "ksql": "$ksqlCmd",
  "streamsProperties": {"ksql.streams.auto.offset.reset":"earliest"}
}
EOF
)
done <ksql.commands
echo -e "\nSleeping 20 seconds after submitting KSQL queries\n"
sleep 20


#################################################################
# Sink: setup cloud storage and create connectors
#################################################################
if [[ "$DESTINATION_STORAGE" == "s3" ]]; then
  # Setup S3 bucket
  bucket_list=$(aws s3api list-buckets --query "Buckets[].Name" --region $STORAGE_REGION | grep $STORAGE_BUCKET_NAME)
  if [[ ! "$bucket_list" =~ "$STORAGE_BUCKET_NAME" ]]; then
    echo "aws s3api create-bucket --bucket $STORAGE_BUCKET_NAME --region $STORAGE_REGION --create-bucket-configuration LocationConstraint=$STORAGE_REGION"
    aws s3api create-bucket --bucket $STORAGE_BUCKET_NAME --region $STORAGE_REGION --create-bucket-configuration LocationConstraint=$STORAGE_REGION
  fi
  # Create connectors to S3
  ccloud connector create -vvv --config <(eval "cat <<EOF
$(<connector_config_s3_no_avro.json)
EOF
")
  if [[ $? != 0 ]]; then echo "Exit status was not 0.  Please troubleshoot and try again"; exit 1 ; fi
  ccloud connector create -vvv --config <(eval "cat <<EOF
$(<connector_config_s3_avro.json)
EOF
")
  if [[ $? != 0 ]]; then echo "Exit status was not 0.  Please troubleshoot and try again"; exit 1 ; fi
else
  # Setup GCS
  bucket_list=$(gsutil ls | grep $STORAGE_BUCKET_NAME)
  if [[ ! "$bucket_list" =~ "$STORAGE_BUCKET_NAME" ]]; then
    echo "gsutil mb -l $STORAGE_REGION gs://$STORAGE_BUCKET_NAME"
    gsutil mb -l $STORAGE_REGION gs://$STORAGE_BUCKET_NAME
  fi
  # Create connectors to GCS
  ccloud connector create -vvv --config <(eval "cat <<EOF
$(<connector_config_gcs_no_avro.json)
EOF
")
  if [[ $? != 0 ]]; then echo "Exit status was not 0.  Please troubleshoot and try again"; exit 1 ; fi
  ccloud connector create -vvv --config <(eval "cat <<EOF
$(<connector_config_gcs_avro.json)
EOF
")
  if [[ $? != 0 ]]; then echo "Exit status was not 0.  Please troubleshoot and try again"; exit 1 ; fi
fi
sleep 10

#################################################################
# Validation: Read Data
#################################################################
./read-data.sh

echo -e "\nDONE!\n"
