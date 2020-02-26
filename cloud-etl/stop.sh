#!/bin/bash

# Source library 
. ../utils/helper.sh

# Source demo-specific configurations
source config/demo.cfg

check_ccloud_config $CONFIG_FILE || exit 1
check_ccloud_logged_in || exit 1

../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE
source delta_configs/env.delta

validate_cloud_storage config/demo.cfg || exit 1

# Set Kafka cluster
ccloud_cli_set_kafka_cluster_use $CLOUD_KEY $CONFIG_FILE || exit 1

# Delete connectors
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
#rm -f data.avro

# Clean up KSQL
echo "Clean up KSQL"
validate_ccloud_ksql "$KSQL_ENDPOINT" "$CONFIG_FILE" "$KSQL_BASIC_AUTH_USER_INFO" || exit 1
# Terminate queries first
ksqlCmd="show queries;"
echo -e "\n\n$ksqlCmd"
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
  echo -e "\n$ksqlCmd"
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
  echo -e "\n$ksqlCmd"
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
echo -e "\n\nClean up Kafka topics: $topics_to_delete"
for topic in $topics_to_delete
do
  ccloud kafka topic delete $topic 2>/dev/null
done

# Delete subjects from Confluent Schema Registry
schema_registry_subjects_to_delete="${KAFKA_TOPIC_NAME_OUT1}-value"
echo -e "\nClean up Confluent Schema Registry subject: $schema_registry_subjects_to_delete"
for subject in $schema_registry_subjects_to_delete
do
  curl -X DELETE --silent -u $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL/subjects/$subject
done

exit 0
