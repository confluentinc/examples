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

# Create topics and create source connector
kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $CONFIG_FILE | tail -1` --command-config $CONFIG_FILE --topic $KAFKA_TOPIC_NAME_IN --create --replication-factor 3 --partitions 6
ccloud connector create -vvv --config <(eval "cat <<EOF
$(<connector_config_kinesis.json)
EOF
")
echo "Sleeping 60 seconds waiting for connector to be in RUNNING state"
sleep 60

#################################################################
# Submit ksqlDB queries
#################################################################
curl -X "POST" "https://<ccloud-ksql-endpoint>/ksql" \
     -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
     -H "Authorization: BASIC base64($CLOUD_KEY:$CLOUD_SECRET)" \
     -d $'{
  "ksql": "$(<ksql.commands)",
  "streamsProperties": {}
}'
echo "Sleeping 20 seconds after submitting ksqlDB queries"
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
  ccloud connector create -vvv --config <(eval "cat <<EOF
$(<connector_config_s3_avro.json)
EOF
")
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
  ccloud connector create -vvv --config <(eval "cat <<EOF
$(<connector_config_gcs_avro.json)
EOF
")
fi
sleep 10

#################################################################
# Validation: Read Data
#################################################################
./read-data.sh

echo -e "\nDONE!\n"
