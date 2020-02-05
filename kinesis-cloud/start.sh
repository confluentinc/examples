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
echo "Sleeping 60 seconds waiting for Kinesis stream to be created"
sleep 60
aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION
while read -r line ; do
  key=$(echo "$line" | awk -F',' '{print $1;}')
  aws kinesis put-record --stream-name $KINESIS_STREAM_NAME --partition-key $key --data $line --region $KINESIS_REGION
done < ../utils/table.locations.csv
echo "Sleeping 10 seconds"
sleep 10

# Create topics and create source connector
ccloud kafka cluster use $(ccloud api-key list | grep "$CLOUD_KEY" | awk '{print $7;}')
kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $CONFIG_FILE | tail -1` --command-config $CONFIG_FILE --topic $KAFKA_TOPIC_NAME_IN --create --replication-factor 3 --partitions 6
ccloud connector create -vvv --config <(eval "cat <<EOF
$(<connector_config_kinesis.json)
EOF
")
if [[ $? != 0 ]]; then echo "Exit status was not 0.  Please troubleshoot and try again"; exit 1 ; fi
echo "Sleeping 60 seconds waiting for connector to be in RUNNING state"
sleep 60

#################################################################
# Submit KSQL queries
#################################################################
validate_ccloud_ksql $KSQL_ENDPOINT || exit 1
ccloud ksql app configure-acls $ksqlAppId $KAFKA_TOPIC_NAME_IN $KAFKA_TOPIC_NAME_OUT1 $KAFKA_TOPIC_NAME_OUT2
while read ksqlCmd; do
  echo -e "\n$ksqlCmd\n"
  curl -X POST $KSQL_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQL_BASIC_AUTH_USER_INFO \
       -d @<(cat <<EOF
{
  "ksql": "$ksqlCmd",
  "streamsProperties": {}
}
EOF
)
done <ksql.commands
echo "Sleeping 20 seconds after submitting KSQL queries"
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
