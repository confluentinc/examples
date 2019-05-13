#!/bin/bash

# Source library 
. ../utils/helper.sh

source config/demo.cfg
SCHEMA_REGISTRY_CONFIG_FILE=$HOME/.ccloud/config
#SCHEMA_REGISTRY_CONFIG_FILE=schema_registry.config
../ccloud/ccloud-generate-cp-configs.sh $SCHEMA_REGISTRY_CONFIG_FILE
source delta_configs/env.delta

check_env || exit 1

# Clean up AWS Kinesis and cloud storage
echo "Clean up AWS Kinesis and cloud storage"
aws kinesis delete-stream --stream-name $KINESIS_STREAM_NAME --region $DEMO_REGION
if [[ "$DESTINATION_STORAGE" == "s3" ]]; then
  aws s3 rm --recursive s3://$DEMO_BUCKET_NAME/topics/${KAFKA_TOPIC_NAME_OUT} --region $DEMO_REGION
  aws s3 rm --recursive s3://$DEMO_BUCKET_NAME/topics/COUNT_PER_CITY --region $DEMO_REGION
else
  # Clean up GCS
  echo "Insert code to clean up GCS"
  exit 1
fi
rm -f data.avro

# Delete topics in Confluent Cloud
topics=$(ccloud topic list)
topics_to_delete="$KAFKA_TOPIC_NAME_IN $KAFKA_TOPIC_NAME_OUT COUNT_PER_CITY connect-configs connect-statuses connect-offsets"
for topic in $topics_to_delete
do
  echo $topics | grep $topic &>/dev/null
  if [[ $? == 0 ]]; then
    ccloud topic delete $topic
  fi
done

# Delete subjects from Confluent Schema Registry
schema_registry_subjects_to_delete="${KAFKA_TOPIC_NAME_OUT}-value"
for subject in $schema_registry_subjects_to_delete
do
  curl -X DELETE --silent -u $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL/subjects/$subject
done

jps | grep ConnectDistributed | awk '{print $1;}' | xargs kill -9
jps | grep KsqlServerMain | awk '{print $1;}' | xargs kill -9
confluent destroy

#../ccloud/ccloud-delete-all-topics.sh
