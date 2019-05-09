#!/bin/bash

# Source library 
. ../utils/helper.sh

source config/demo.cfg

check_env || exit 1

aws kinesis delete-stream --stream-name $KINESIS_STREAM_NAME
aws s3 rm --recursive s3://$DEMO_BUCKET_NAME/topics/${KAFKA_TOPIC_NAME}
rm -f data.avro

# Delete topics in Confluent Cloud
topics=$(ccloud topic list)
topics_to_delete="$KAFKA_TOPIC_NAME connect-configs connect-statuses connect-offsets"
for topic in $topics_to_delete
do
  echo $topics | grep $topic &>/dev/null
  if [[ $? == 0 ]]; then
    ccloud topic delete $topic
  fi
done

jps | grep ConnectDistributed | awk '{print $1;}' | xargs kill -9
confluent destroy
