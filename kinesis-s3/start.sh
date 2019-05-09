#!/bin/bash

# Source library
. ../utils/helper.sh

source $HOME/.aws/credentials-demo
source config/demo.cfg

check_env || exit 1
check_running_cp 5.2 || exit
check_aws || exit

./stop.sh

# Install Connectors and start Confluent Platform
confluent-hub install confluentinc/kafka-connect-kinesis:latest --no-prompt
confluent-hub install confluentinc/kafka-connect-s3:latest --no-prompt
confluent start
sleep 10

# Verify connector plugins are found
curl -sS localhost:8083/connector-plugins | jq '.[].class' | grep Kinesis
curl -sS localhost:8083/connector-plugins | jq '.[].class' | grep S3

# Setup Kinesis streams
aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1
echo "Sleeping 60 seconds waiting for Kinesis stream to be created"
sleep 60
aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME
for i in {1..10}
do
  aws kinesis put-record --stream-name $KINESIS_STREAM_NAME --partition-key alice --data x$i
done
while read -r line ; do echo "$line" | base64 -id; echo; done <<< $(aws kinesis get-records --shard-iterator $(aws kinesis get-shard-iterator --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --stream-name $KINESIS_STREAM_NAME --query 'ShardIterator') | jq '.Records[].Data')

# Setup AWS S3 bucket
bucket_exists=$(aws s3api list-buckets --query "Buckets[].Name" | grep $DEMO_BUCKET_NAME)
if [[ ! "$bucket_exists" =~ "$DEMO_BUCKET_NAME" ]]; then
  echo "aws s3api create-bucket --bucket $DEMO_BUCKET_NAME --region $DEMO_REGION_LC --create-bucket-configuration LocationConstraint=$DEMO_REGION_LC"
  aws s3api create-bucket --bucket $DEMO_BUCKET_NAME --region $DEMO_REGION_LC --create-bucket-configuration LocationConstraint=$DEMO_REGION_LC
fi

# Submit connectors
if is_ce; then
  . ./connectors/submit_kinesis_config.sh
  . ./connectors/submit_s3_config.sh
fi
sleep 5

# Read data
echo -e "\ntimeout 10 confluent consume $KAFKA_TOPIC_NAME --from-beginning"
timeout 10 confluent consume $KAFKA_TOPIC_NAME --from-beginning
echo "aws s3api list-objects --bucket $DEMO_BUCKET_NAME"
aws s3api list-objects --bucket $DEMO_BUCKET_NAME
aws s3 cp s3://$DEMO_BUCKET_NAME/topics/$KAFKA_TOPIC_NAME/partition=0/${KAFKA_TOPIC_NAME}+0+0000000000.avro .
if [[ ! -f avro-tools-1.8.2.jar ]]; then
  curl -L http://mirror.metrocast.net/apache/avro/avro-1.8.2/java/avro-tools-1.8.2.jar --output avro-tools-1.8.2.jar
fi
echo "java -jar avro-tools-1.8.2.jar tojson ${KAFKA_TOPIC_NAME}+0+0000000000.avro"
java -jar avro-tools-1.8.2.jar tojson ${KAFKA_TOPIC_NAME}+0+0000000000.avro 2>/dev/null 

#ksql http://localhost:8088 <<EOF
#run script 'ksql.commands';
#exit ;
#EOF

# TODO
# - rename credentials-demo
# - create kinesis stream and add messages
# - clean up AWS bucket
