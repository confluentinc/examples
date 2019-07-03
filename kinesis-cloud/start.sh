#!/bin/bash

# Source library
. ../utils/helper.sh

source config/demo.cfg

check_env || exit 1
check_running_cp 5.3 || exit

if [[ "$DESTINATION_STORAGE" == "s3" ]]; then
  check_aws || exit
else
  check_gcp_creds || exit
  check_gsutil || exit
fi

./stop.sh

# Install Connectors and start Confluent Platform
confluent-hub install confluentinc/kafka-connect-kinesis:latest --no-prompt
if [[ "$DESTINATION_STORAGE" == "s3" ]]; then
  confluent-hub install confluentinc/kafka-connect-s3:latest --no-prompt
else
  confluent-hub install confluentinc/kafka-connect-gcs:latest --no-prompt
fi

#---------------------------------
# Option 1: Confluent Cloud SR
#SCHEMA_REGISTRY_CONFIG_FILE=$HOME/.ccloud/config

# Option 2: local Confluent SR
SCHEMA_REGISTRY_CONFIG_FILE=schema_registry.config
confluent local start schema-registry
#---------------------------------

# Generate CCloud configurations
../ccloud/ccloud-generate-cp-configs.sh $SCHEMA_REGISTRY_CONFIG_FILE
CONFLUENT_CURRENT=`confluent local current | tail -1`
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

# Start Connect that connects to CCloud cluster
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
connect-distributed $CONNECT_CONFIG > $CONFLUENT_CURRENT/connect/connect-ccloud.stdout 2>&1 &
#echo "Sleeping 40 seconds waiting for Connect to start"
#sleep 40

# Create and populate Kinesis streams
echo "aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1 --region $KINESIS_REGION"
aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1 --region $KINESIS_REGION
if [[ $? != 0 ]]; then
  echo "ERROR: Received a non-zero exit code when trying to create the AWS Kinesis stream. Please troubleshoot"
  exit $?
fi
echo "Sleeping 60 seconds waiting for Kinesis stream to be created"
sleep 60
aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME --region $KINESIS_REGION
while read -r line ; do
  key=$(echo "$line" | awk -F',' '{print $1;}')
  aws kinesis put-record --stream-name $KINESIS_STREAM_NAME --partition-key $key --data $line --region $KINESIS_REGION
done < ../utils/table.locations.csv

# Setup cloud storage
if [[ "$DESTINATION_STORAGE" == "s3" ]]; then
  # Setup S3 bucket
  bucket_list=$(aws s3api list-buckets --query "Buckets[].Name" --region $STORAGE_REGION | grep $STORAGE_BUCKET_NAME)
  if [[ ! "$bucket_list" =~ "$STORAGE_BUCKET_NAME" ]]; then
    echo "aws s3api create-bucket --bucket $STORAGE_BUCKET_NAME --region $STORAGE_REGION --create-bucket-configuration LocationConstraint=$STORAGE_REGION"
    aws s3api create-bucket --bucket $STORAGE_BUCKET_NAME --region $STORAGE_REGION --create-bucket-configuration LocationConstraint=$STORAGE_REGION
  fi
else
  # Setup GCS
  bucket_list=$(gsutil ls | grep $STORAGE_BUCKET_NAME)
  if [[ ! "$bucket_list" =~ "$STORAGE_BUCKET_NAME" ]]; then
    echo "gsutil mb -l $STORAGE_REGION gs://$STORAGE_BUCKET_NAME"
    gsutil mb -l $STORAGE_REGION gs://$STORAGE_BUCKET_NAME
  fi
fi

# Submit connectors
# Verify connector plugins are found
curl -sS localhost:$CONNECT_REST_PORT/connector-plugins | jq '.[].class' | grep Kinesis
curl -sS localhost:$CONNECT_REST_PORT/connector-plugins | jq '.[].class' | grep S3
ccloud topic create $KAFKA_TOPIC_NAME_IN
ccloud topic create $KAFKA_TOPIC_NAME_OUT
. ./submit_kinesis_config.sh
sleep 20

# KSQL Server runs locally and connects to Confluent Cloud
jps | grep KsqlServerMain | awk '{print $1;}' | xargs kill -9
mkdir -p $CONFLUENT_CURRENT/ksql-server
KSQL_SERVER_CONFIG=$CONFLUENT_CURRENT/ksql-server/ksql-server-ccloud.properties
cp $DELTA_CONFIGS_DIR/ksql-server-ccloud.delta $KSQL_SERVER_CONFIG
# Set this new KSQL Server listener to port $KSQL_LISTENER instead of default 8088 which is already in use
KSQL_LISTENER=8089
cat <<EOF >> $KSQL_SERVER_CONFIG
listeners=http://localhost:$KSQL_LISTENER
ksql.server.ui.enabled=true
auto.offset.reset=earliest
commit.interval.ms=0
cache.max.bytes.buffering=0
auto.offset.reset=earliest
state.dir=$CONFLUENT_CURRENT/ksql-server/data-ccloud/kafka-streams
EOF
echo -e "\nStarting KSQL Server to Confluent Cloud and sleeping 25 seconds"
ksql-server-start $KSQL_SERVER_CONFIG > $CONFLUENT_CURRENT/ksql-server/ksql-server-ccloud.stdout 2>&1 &
sleep 25
ksql http://localhost:$KSQL_LISTENER <<EOF
run script 'ksql.commands';
exit ;
EOF

echo "Sleeping 20 seconds after submitting KSQL queries"
sleep 20

if [[ "$DESTINATION_STORAGE" == "s3" ]]; then
  # Submit connectors to S3
  . ./submit_s3_config_no_avro.sh
  . ./submit_s3_config_avro.sh
else
  # Submit connectors to GCS
  . ./submit_gcs_config_no_avro.sh
  . ./submit_gcs_config_avro.sh
fi

sleep 10

./read-data.sh

echo -e "\n\n\n******************************************************************"
echo -e "DONE!"
echo -e "******************************************************************\n"
