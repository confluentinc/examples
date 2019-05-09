#!/bin/bash

# Source library
. ../utils/helper.sh

source config/demo.cfg

check_env || exit 1
check_running_cp 5.2 || exit
check_aws || exit

./stop.sh

# Install Connectors and start Confluent Platform
confluent-hub install confluentinc/kafka-connect-kinesis:latest --no-prompt
confluent-hub install confluentinc/kafka-connect-s3:latest --no-prompt

# Start Connect that connects to CCloud cluster
CONFLUENT_CURRENT=`confluent current | tail -1`
SCHEMA_REGISTRY_CONFIG_FILE=../ccloud/schema_registry.config
../ccloud/ccloud-generate-cp-configs.sh $SCHEMA_REGISTRY_CONFIG_FILE
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta
mkdir -p $CONFLUENT_CURRENT/connect
CONNECT_CONFIG=$CONFLUENT_CURRENT/connect/connect-ccloud.properties
cp $CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties $CONNECT_CONFIG
cat $DELTA_CONFIGS_DIR/connect-ccloud.delta >> $CONNECT_CONFIG
CONNECT_REST_PORT=8087
cat <<EOF >> $CONNECT_CONFIG
rest.port=$CONNECT_REST_PORT
rest.advertised.name=connect-cloud
rest.hostname=connect-cloud
group.id=connect-cloud
request.timeout.ms=20000
retry.backoff.ms=500
plugin.path=$CONFLUENT_HOME/share/java,$CONFLUENT_HOME/share/confluent-hub-components
EOF
export CLASSPATH=$CONFLUENT_HOME/kafka-connect-replicator/kafka-connect-replicator-5.2.1.jar && connect-distributed $CONNECT_CONFIG > $CONFLUENT_CURRENT/connect/connect-ccloud.stdout 2>&1 &
sleep 40

# Verify connector plugins are found
curl -sS localhost:$CONNECT_REST_PORT/connector-plugins | jq '.[].class' | grep Kinesis
curl -sS localhost:$CONNECT_REST_PORT/connector-plugins | jq '.[].class' | grep S3

# Setup Kinesis streams
aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1
echo "Sleeping 60 seconds waiting for Kinesis stream to be created"
sleep 60
aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME
for i in {1..10}
do
  aws kinesis put-record --stream-name $KINESIS_STREAM_NAME --partition-key alice --data m$i
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
  ccloud topic create $KAFKA_TOPIC_NAME
  . ./submit_kinesis_config.sh
  . ./submit_s3_config.sh
fi
sleep 20

# Read data
echo -e "\ntimeout 10 confluent consume $KAFKA_TOPIC_NAME --cloud --from-beginning"
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
