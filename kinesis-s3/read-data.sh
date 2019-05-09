#!/bin/bash

# Source library
. ../utils/helper.sh

source config/demo.cfg

check_env || exit 1
check_running_cp 5.2 || exit
check_aws || exit

echo -e "\nKinesis data:"
while read -r line ; do echo "$line" | base64 -id; echo; done <<< $(aws kinesis get-records --shard-iterator $(aws kinesis get-shard-iterator --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --stream-name $KINESIS_STREAM_NAME --query 'ShardIterator') | jq '.Records[].Data')

echo -e "\nKafka topic data:"
echo -e "\ntimeout 10 confluent consume $KAFKA_TOPIC_NAME --cloud --from-beginning"
timeout 10 confluent consume $KAFKA_TOPIC_NAME --cloud --from-beginning
#echo -e "\ntimeout 10 ccloud consume -t $KAFKA_TOPIC_NAME -b"
#timeout 10 ccloud consume -t $KAFKA_TOPIC_NAME -b

echo -e "\nS3 data:"
echo "aws s3api list-objects --bucket $DEMO_BUCKET_NAME"
aws s3api list-objects --bucket $DEMO_BUCKET_NAME
aws s3 cp s3://$DEMO_BUCKET_NAME/$(aws s3api list-objects --bucket confluent-kafka-connect-s3-demo | jq -r '.Contents[].Key') data.avro
if [[ ! -f avro-tools-1.8.2.jar ]]; then
  curl -L http://mirror.metrocast.net/apache/avro/avro-1.8.2/java/avro-tools-1.8.2.jar --output avro-tools-1.8.2.jar
fi
echo "java -jar avro-tools-1.8.2.jar tojson data.avro"
java -jar avro-tools-1.8.2.jar tojson data.avro
