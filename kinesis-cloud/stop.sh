#!/bin/bash

# Source library 
. ../utils/helper.sh

CONFIG_FILE=~/.ccloud/config
check_ccloud_config $CONFIG_FILE || exit
check_ccloud_logged_in || exit

source config/demo.cfg
SCHEMA_REGISTRY_CONFIG_FILE=$HOME/.ccloud/config
#SCHEMA_REGISTRY_CONFIG_FILE=schema_registry.config
../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE $SCHEMA_REGISTRY_CONFIG_FILE
source delta_configs/env.delta

check_env || exit 1

validate_cloud_storage $DESTINATION_STORAGE || exit

# Delete connectors
#for connector in demo-KinesisSource demo-GcsSink-avro demo-GcsSink-no-avro demo-S3Sink-avro demo-S3Sink-no-avro; do
for f in connectors/*.json; do
  connector=$(cat $f | jq -r .name)
  connectorId=$(ccloud connector list | grep $connector | awk '{print $1}')
  if [[ "$connectorId" != "" ]]; then
    echo "Deleting connector $connector with id $connectorId"
    ccloud connector delete $connectorId
  fi
done

# Clean up AWS Kinesis and cloud storage
echo "Clean up AWS Kinesis"
aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION --profile $AWS_PROFILE > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  aws kinesis delete-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION --profile $AWS_PROFILE
fi
echo "Clean up $DESTINATION_STORAGE cloud storage"
if [[ "$DESTINATION_STORAGE" == "s3" ]]; then
  aws s3 rm --recursive s3://$STORAGE_BUCKET_NAME/topics/${KAFKA_TOPIC_NAME_OUT1} --region $STORAGE_REGION --profile $STORAGE_PROFILE
  aws s3 rm --recursive s3://$STORAGE_BUCKET_NAME/topics/${KAFKA_TOPIC_NAME_OUT2} --region $STORAGE_REGION --profile $STORAGE_PROFILE
elif [[ "$DESTINATION_STORAGE" == "gcs" ]]; then
  check_gsutil || exit
  # Clean up GCS
  gsutil rm -r gs://$STORAGE_BUCKET_NAME/**
else
  export AZBLOB_ACCOUNT_NAME=$STORAGE_PROFILE
  export AZBLOB_ACCOUNT_KEY=$(az storage account keys list --account-name $AZBLOB_ACCOUNT_NAME | jq -r '.[0].value')
  az storage container delete --name $STORAGE_BUCKET_NAME --account-name $AZBLOB_ACCOUNT_NAME --account-key $AZBLOB_ACCOUNT_KEY
fi
#rm -f data.avro

# Clean up KSQL
echo "Clean up KSQL"
validate_ccloud_ksql $KSQL_ENDPOINT || exit 1
# Terminate queries first
ksqlCmd="show queries;"
echo -e "\n$ksqlCmd\n"
queries=$(curl --silent -X POST $KSQL_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQL_BASIC_AUTH_USER_INFO \
       -d @<(cat <<EOF
{
  "ksql": "$ksqlCmd",
  "streamsProperties": {}
}
EOF
) | jq -r '.[0].queries[].id')
for q in $queries; do
  ksqlCmd="TERMINATE $q;"
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
done
# Terminate streams and tables
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
done <ksql.cleanup.commands

# Delete topics in Confluent Cloud
topics_to_delete="$KAFKA_TOPIC_NAME_IN $KAFKA_TOPIC_NAME_OUT1 $KAFKA_TOPIC_NAME_OUT2"
for topic in $topics_to_delete
do
  ccloud kafka topic delete $topic 2>/dev/null
done

# Delete subjects from Confluent Schema Registry
schema_registry_subjects_to_delete="${KAFKA_TOPIC_NAME_OUT1}-value"
for subject in $schema_registry_subjects_to_delete
do
  curl -X DELETE --silent -u $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL/subjects/$subject
done
