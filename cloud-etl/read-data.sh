#!/bin/bash

# Source library
. ../utils/helper.sh

source config/demo.cfg
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

check_aws || exit 1
check_timeout || exit 1

echo -e "\nRead data to validate end-to-end processing\n"

echo -e "\nData from Kinesis stream $KINESIS_STREAM_NAME --limit 10:"
while read -r line ; do echo "$line" | base64 --decode; echo; done <<< "$(aws kinesis get-records --region $KINESIS_REGION --shard-iterator $(aws kinesis get-shard-iterator --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --stream-name $KINESIS_STREAM_NAME --query 'ShardIterator' --region $KINESIS_REGION) --limit 10 | jq -r '.Records[].Data')"

if check_confluent_binary; then

  check_running_cp ${CP_VERSION_FULL} || exit

  echo -e "\nData from Kafka topic $KAFKA_TOPIC_NAME_IN:"
  echo -e "confluent local consume $KAFKA_TOPIC_NAME_IN -- --cloud --from-beginning --property print.key=true --max-messages 10"
  export KAFKA_LOG4J_OPTS="-Dlog4j.rootLogger=DEBUG,stdout -Dlog4j.logger.kafka=DEBUG,stdout" && timeout 10 confluent local consume $KAFKA_TOPIC_NAME_IN -- --cloud --from-beginning --property print.key=true --max-messages 10 2>/dev/null

  echo -e "\nData from Kafka topic $KAFKA_TOPIC_NAME_OUT2:"
  echo -e "confluent local consume $KAFKA_TOPIC_NAME_OUT2 -- --cloud --from-beginning --property print.key=true --max-messages 10"
  export KAFKA_LOG4J_OPTS="-Dlog4j.rootLogger=DEBUG,stdout -Dlog4j.logger.kafka=DEBUG,stdout" && timeout 10 confluent local consume $KAFKA_TOPIC_NAME_OUT2 -- --cloud --from-beginning --property print.key=true --max-messages 10 2>/dev/null

  echo -e "\nData from Kafka topic $KAFKA_TOPIC_NAME_OUT1:"
  echo -e "confluent local consume $KAFKA_TOPIC_NAME_OUT1 -- --cloud --from-beginning --property print.key=true --value-format avro --property basic.auth.credentials.source=${BASIC_AUTH_CREDENTIALS_SOURCE} --property schema.registry.basic.auth.user.info=${SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO} --property schema.registry.url=${SCHEMA_REGISTRY_URL} --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --max-messages 10"
  export KAFKA_LOG4J_OPTS="-Dlog4j.rootLogger=DEBUG,stdout -Dlog4j.logger.kafka=DEBUG,stdout" && timeout 10 confluent local consume $KAFKA_TOPIC_NAME_OUT1 -- --cloud --from-beginning --property print.key=true --value-format avro --property basic.auth.credentials.source=${BASIC_AUTH_CREDENTIALS_SOURCE} --property schema.registry.basic.auth.user.info=${SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO} --property schema.registry.url=${SCHEMA_REGISTRY_URL} --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --max-messages 10 2>/dev/null

else

  echo "Skipping reading the Kafka topics."

fi

echo -e "\nObjects in Cloud storage $DESTINATION_STORAGE:\n"
AVRO_VERSION=1.9.1
#if [[ ! -f avro-tools-${AVRO_VERSION}.jar ]]; then
#  curl -L http://mirror.metrocast.net/apache/avro/avro-${AVRO_VERSION}/java/avro-tools-${AVRO_VERSION}.jar --output avro-tools-${AVRO_VERSION}.jar
#fi
if [[ "$DESTINATION_STORAGE" == "s3" ]]; then
  for key in $(aws s3api list-objects --bucket $S3_BUCKET | jq -r '.Contents[].Key'); do
    echo "S3 key: $key"
    #aws s3 cp s3://$S3_BUCKET/$key data.avro
    #echo "java -Dlog4j.configuration="file:log4j.properties" -jar avro-tools-${AVRO_VERSION}.jar tojson data.avro"
    #java -Dlog4j.configuration="file:log4j.properties" -jar avro-tools-${AVRO_VERSION}.jar tojson data.avro
  done
elif [[ "$DESTINATION_STORAGE" == "gcs" ]]; then
  gsutil ls -r gs://$GCS_BUCKET
else
  export AZBLOB_ACCOUNT_KEY=$(az storage account keys list --account-name $AZBLOB_STORAGE_ACCOUNT | jq -r '.[0].value')
  #az storage blob list --container-name $AZBLOB_CONTAINER --account-name $AZBLOB_STORAGE_ACCOUNT --account-key $AZBLOB_ACCOUNT_KEY --prefix "topics/$KAFKA_TOPIC_NAME_OUT1" | jq -r '.[].name'
  az storage blob list --container-name $AZBLOB_CONTAINER --account-name $AZBLOB_STORAGE_ACCOUNT --account-key $AZBLOB_ACCOUNT_KEY --prefix "topics/$KAFKA_TOPIC_NAME_OUT2" | jq -r '.[].name'
fi
