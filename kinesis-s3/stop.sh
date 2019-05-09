#!/bin/bash

# Source library 
. ../utils/helper.sh

source config/demo.cfg

check_env || exit 1

aws kinesis delete-stream --stream-name $KINESIS_STREAM_NAME
aws s3 rm --recursive s3://$DEMO_BUCKET_NAME/topics/${KAFKA_TOPIC_NAME}
rm -f ${KAFKA_TOPIC_NAME}+0+0000000000.avro

confluent destroy
