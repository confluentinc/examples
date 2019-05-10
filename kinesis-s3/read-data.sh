#!/bin/bash

# Source library
. ../utils/helper.sh

source config/demo.cfg
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

check_env || exit 1
check_aws || exit

echo -e "\n\nKinesis data:"
while read -r line ; do echo "$line" | base64 -id; echo; done <<< "$(aws kinesis get-records --shard-iterator $(aws kinesis get-shard-iterator --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --stream-name $KINESIS_STREAM_NAME --query 'ShardIterator') | jq '.Records[].Data')"

echo -e "\nKafka topic data:"
echo -e "timeout 10 confluent consume $KAFKA_TOPIC_NAME_IN --cloud --from-beginning --property print.key=true"
timeout 10 confluent consume $KAFKA_TOPIC_NAME_IN --cloud --from-beginning --property print.key=true
echo -e "timeout 10 confluent consume COUNT_PER_CITY --cloud --from-beginning --property print.key=true"
timeout 10 confluent consume COUNT_PER_CITY --cloud --from-beginning --property print.key=true
echo -e "timeout 10 confluent consume $KAFKA_TOPIC_NAME_OUT --cloud --from-beginning --property print.key=true --value-format avro --property basic.auth.credentials.source=${BASIC_AUTH_CREDENTIALS_SOURCE} --property schema.registry.basic.auth.user.info=${SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO} --property schema.registry.url=${SCHEMA_REGISTRY_URL} --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer"
timeout 10 confluent consume $KAFKA_TOPIC_NAME_OUT --cloud --from-beginning --property print.key=true --value-format avro --property basic.auth.credentials.source=${BASIC_AUTH_CREDENTIALS_SOURCE} --property schema.registry.basic.auth.user.info=${SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO} --property schema.registry.url=${SCHEMA_REGISTRY_URL} --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer

echo -e "\nS3 data:"
if [[ ! -f avro-tools-1.8.2.jar ]]; then
  curl -L http://mirror.metrocast.net/apache/avro/avro-1.8.2/java/avro-tools-1.8.2.jar --output avro-tools-1.8.2.jar
fi
for key in $(aws s3api list-objects --bucket confluent-kafka-connect-s3-demo | jq -r '.Contents[].Key'); do
  aws s3 cp s3://$DEMO_BUCKET_NAME/$key data.avro
  echo "java -jar avro-tools-1.8.2.jar tojson data.avro"
  java -jar avro-tools-1.8.2.jar tojson data.avro
done
