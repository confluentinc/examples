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

#---------------------------------
# Option 1: Confluent Cloud SR
#SCHEMA_REGISTRY_CONFIG_FILE=$HOME/.ccloud/config

# Option 2: local Confluent SR
SCHEMA_REGISTRY_CONFIG_FILE=schema_registry.config
confluent start schema-registry
#---------------------------------

# Generate CCloud configurations
../ccloud/ccloud-generate-cp-configs.sh $SCHEMA_REGISTRY_CONFIG_FILE
CONFLUENT_CURRENT=`confluent current | tail -1`
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
export CLASSPATH=$CONFLUENT_HOME/kafka-connect-replicator/kafka-connect-replicator-5.2.1.jar && connect-distributed $CONNECT_CONFIG > $CONFLUENT_CURRENT/connect/connect-ccloud.stdout 2>&1 &
#echo "Sleeping 40 seconds waiting for Connect to start"
#sleep 40

# Setup Kinesis streams
aws kinesis create-stream --stream-name $KINESIS_STREAM_NAME --shard-count 1
echo "Sleeping 60 seconds waiting for Kinesis stream to be created"
sleep 60
aws kinesis describe-stream --stream-name $KINESIS_STREAM_NAME
while read -r line ; do
  key=$(echo "$line" | awk -F',' '{print $1;}')
  aws kinesis put-record --stream-name $KINESIS_STREAM_NAME --partition-key $key --data $line
done < ../utils/table.locations.csv

# Setup AWS S3 bucket
bucket_exists=$(aws s3api list-buckets --query "Buckets[].Name" | grep $DEMO_BUCKET_NAME)
if [[ ! "$bucket_exists" =~ "$DEMO_BUCKET_NAME" ]]; then
  echo "aws s3api create-bucket --bucket $DEMO_BUCKET_NAME --region $DEMO_REGION_LC --create-bucket-configuration LocationConstraint=$DEMO_REGION_LC"
  aws s3api create-bucket --bucket $DEMO_BUCKET_NAME --region $DEMO_REGION_LC --create-bucket-configuration LocationConstraint=$DEMO_REGION_LC
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

. ./submit_s3_config_no_avro.sh
. ./submit_s3_config_avro.sh

sleep 10

./read-data.sh

echo -e "\n\n\n******************************************************************"
echo -e "DONE!"
echo -e "******************************************************************\n"
