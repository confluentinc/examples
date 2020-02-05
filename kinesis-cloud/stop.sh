#!/bin/bash

# Source library 
. ../utils/helper.sh

CONFIG_FILE=~/.ccloud/config
check_ccloud_config $CONFIG_FILE || exit

source config/demo.cfg
SCHEMA_REGISTRY_CONFIG_FILE=$HOME/.ccloud/config
#SCHEMA_REGISTRY_CONFIG_FILE=schema_registry.config
../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE $SCHEMA_REGISTRY_CONFIG_FILE
source delta_configs/env.delta

check_env || exit 1
check_aws || exit

# Delete connectors
for connector in demo-KinesisSource demo-GcsSink-avro demo-GcsSink-no-avro demo-S3Sink-avro demo-S3Sink-no-avro; do
  connectorId=$(ccloud connector list | grep $connector | awk '{print $1}')
  if [[ "$connectorId" != "" ]]; then
    echo "Deleting connector $connector with id $connectorId"
    ccloud connector delete $connectorId
  fi
done

# Clean up AWS Kinesis and cloud storage
source $AWS_CREDENTIALS_FILE
echo "Clean up AWS Kinesis and cloud storage"
aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  aws kinesis delete-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION
fi
if [[ "$DESTINATION_STORAGE" == "s3" ]]; then
  aws s3 rm --recursive s3://$STORAGE_BUCKET_NAME/topics/${KAFKA_TOPIC_NAME_OUT1} --region $STORAGE_REGION
  aws s3 rm --recursive s3://$STORAGE_BUCKET_NAME/topics/${KAFKA_TOPIC_NAME_OUT2} --region $STORAGE_REGION
else
  check_gsutil || exit
  # Clean up GCS
  gsutil rm -r gs://$STORAGE_BUCKET_NAME/**
fi
rm -f data.avro

# Delete topics in Confluent Cloud
topics=$(kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --command-config delta_configs/ak-tools-ccloud.delta --list)
topics_to_delete="$KAFKA_TOPIC_NAME_IN $KAFKA_TOPIC_NAME_OUT1 $KAFKA_TOPIC_NAME_OUT2 connect-configs connect-statuses connect-offsets"
for topic in $topics_to_delete
do
  echo $topics | grep $topic &>/dev/null
  if [[ $? == 0 ]]; then
    kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --command-config delta_configs/ak-tools-ccloud.delta --delete --topic $topic
  fi
done

# Delete subjects from Confluent Schema Registry
schema_registry_subjects_to_delete="${KAFKA_TOPIC_NAME_OUT1}-value"
for subject in $schema_registry_subjects_to_delete
do
  curl -X DELETE --silent -u $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL/subjects/$subject
done


#../ccloud/ccloud-delete-all-topics.sh
