#!/bin/bash

# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

# Source demo-specific configurations
source config/demo.cfg

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './start.sh'. (Is it in stack-configs/ folder?) "
  exit 1
else
  CONFIG_FILE=$1
fi

ccloud::validate_aws_cli_installed || exit 1
check_timeout || exit 1

echo -e "\nRead data to validate end-to-end processing\n"

if [[ "${DATA_SOURCE}" == "kinesis" ]]; then

  echo -e "\nData from Kinesis stream $KINESIS_STREAM_NAME --limit 10:"
  while read -r line ; do echo "$line" | base64 --decode; echo; done <<< "$(aws kinesis get-records --region $KINESIS_REGION --shard-iterator $(aws kinesis get-shard-iterator --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --stream-name $KINESIS_STREAM_NAME --query 'ShardIterator' --region $KINESIS_REGION) --limit 10 | jq -r '.Records[].Data')"

elif [[ "${DATA_SOURCE}" == "rds" ]]; then

  echo -e "\nData from PostgreSQL database $DB_INSTANCE_IDENTIFIER in AWS RDS with limit 10:"
  export CONNECTION_HOST=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --region $RDS_REGION --profile $AWS_PROFILE | jq -r ".DBInstances[0].Endpoint.Address")
  export CONNECTION_PORT=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --region $RDS_REGION --profile $AWS_PROFILE | jq -r ".DBInstances[0].Endpoint.Port")
  PGPASSWORD=pg12345678 psql \
     --host $CONNECTION_HOST \
     --port $CONNECTION_PORT \
     --username pg \
     --dbname $DB_INSTANCE_IDENTIFIER \
     --command "select * from $KAFKA_TOPIC_NAME_IN limit 10;"

  KAFKA_TOPIC_NAME_IN='rds-eventlogs'

fi

CLUSTER_ID=$(confluent kafka cluster list -o json | jq -r '.[0].id')
if [ -z "$CLUSTER_ID" ]; then
  echo "Cluster not found; please troubleshoot exiting now"
  exit 1
else
  echo "Using cluster id $CLUSTER_ID"

  SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO=$( grep "^basic.auth.user.info" $CONFIG_FILE | awk -F'=' '{print $2;}' )
  SCHEMA_REGISTRY_URL=$( grep "^schema.registry.url" $CONFIG_FILE | awk -F'=' '{print $2;}' )
  SR_KEY=$(echo $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO | cut -d ':' -f 1)
  SR_SECRET=$(echo $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO | cut -d ':' -f 2)

  echo -e "\nData from Kafka topic $KAFKA_TOPIC_NAME_IN:"
  echo -e "confluent kafka topic consume $KAFKA_TOPIC_NAME_IN --cluster $CLUSTER_ID --api-key $CLOUD_KEY --api-secret $CLOUD_SECRET --from-beginning --print-key"
  timeout 5 confluent kafka topic consume $KAFKA_TOPIC_NAME_IN --cluster $CLUSTER_ID\
   --api-key $CLOUD_KEY\
   --api-secret $CLOUD_SECRET\
   --from-beginning\
   --print-key

  echo -e "\nData from Kafka topic $KAFKA_TOPIC_NAME_OUT2:"
  echo -e "confluent kafka topic consume $KAFKA_TOPIC_NAME_OUT2 --cluster $CLUSTER_ID --api-key $CLOUD_KEY --api-secret $CLOUD_SECRET --from-beginning --print-key"
  timeout 5 confluent kafka topic consume $KAFKA_TOPIC_NAME_OUT2 --cluster $CLUSTER_ID\
   --api-key $CLOUD_KEY\
   --api-secret $CLOUD_SECRET\
   --from-beginning\
   --print-key

  echo -e "\nData from Kafka topic $KAFKA_TOPIC_NAME_OUT1:"
  echo -e "confluent kafka consume $KAFKA_TOPIC_NAME_OUT1 --cluster $CLUSTER_ID --config-file $CONFIG_FILE --from-beginning --print-key --value-format avro"
  timeout 5 confluent kafka topic consume $KAFKA_TOPIC_NAME_OUT1 --cluster $CLUSTER_ID\
    --api-key $CLOUD_KEY\
    --api-secret $CLOUD_SECRET\
    --schema-registry-api-key $SR_KEY\
    --schema-registry-api-secret $SR_SECRET\
    --schema-registry-endpoint $SCHEMA_REGISTRY_URL\
    --from-beginning\
    --print-key\
    --value-format avro
fi


echo -e "\nObjects in Cloud storage $DESTINATION_STORAGE:\n"
AVRO_VERSION=1.9.1
#if [[ ! -f avro-tools-${AVRO_VERSION}.jar ]]; then
#  curl -L http://mirror.metrocast.net/apache/avro/avro-${AVRO_VERSION}/java/avro-tools-${AVRO_VERSION}.jar --output avro-tools-${AVRO_VERSION}.jar
#fi
if [[ "$DESTINATION_STORAGE" == "s3" ]]; then

  for key in $(aws s3api list-objects --bucket $S3_BUCKET --profile $S3_PROFILE | jq -r '.Contents[].Key'); do
    echo "S3 key: $key"
    #aws s3 cp s3://$S3_BUCKET/$key data.avro
    #echo "java -Dlog4j.configuration="file:log4j.properties" -jar avro-tools-${AVRO_VERSION}.jar tojson data.avro"
    #java -Dlog4j.configuration="file:log4j.properties" -jar avro-tools-${AVRO_VERSION}.jar tojson data.avro
  done

elif [[ "$DESTINATION_STORAGE" == "gcs" ]]; then

  gsutil ls -p $GCS_PROJECT_ID -r gs://$GCS_BUCKET

else

  export AZBLOB_ACCOUNT_KEY=$(az storage account keys list --account-name $AZBLOB_STORAGE_ACCOUNT | jq -r '.[0].value')
  az storage blob list --container-name $AZBLOB_CONTAINER --account-name $AZBLOB_STORAGE_ACCOUNT --account-key $AZBLOB_ACCOUNT_KEY --prefix "topics/$KAFKA_TOPIC_NAME_OUT2" | jq -r '.[].name'

fi
