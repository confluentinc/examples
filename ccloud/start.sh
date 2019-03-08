#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_jq || exit 1
check_running_cp 5.1 || exit 1
check_ccloud || exit 1

if ! is_ce ; then
  echo "This demo uses Confluent Replicator which requires Confluent Platform, however this host is running Confluent Community software. Exiting"
  exit 1
fi

./stop.sh

confluent start
CONFLUENT_CURRENT=`confluent current | tail -1`

DELTA_CONFIGS_DIR="delta_configs"
./ccloud-generate-cp-configs.sh $DELTA_CONFIGS_DIR

source delta_configs/env.delta

SR_PROPERTIES_FILE=$CONFLUENT_CURRENT/schema-registry/confluent-cloud-schema-registry.properties
USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY=1
if [[ $USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY == 1 ]]; then
  # Use Confluent Cloud Schema Registry
  cp $DELTA_CONFIGS_DIR/confluent-cloud-schema-registry.properties $SR_PROPERTIES_FILE
  curl --silent -u $SR_BASIC_AUTH_USER_INFO $SR_URL
  if [[ "$?" -ne 0 ]]; then
    echo "ERROR: Could not validate credentials to Confluent Cloud Schema Registry. Please troubleshoot"
    exit
  fi
else
  # Confluent Schema Registry runs locally and connects to Confluent Cloud
  # Set this new Schema Registry listener to port $SR_LISTENER instead of the default 8081 which is already in use
  SR_LISTENER=8085
  echo "schema.registry.url=http://localhost:$SR_LISTENER" > $SR_PROPERTIES_FILE
  SR_CONFIG=$CONFLUENT_CURRENT/schema-registry/schema-registry-ccloud.properties
  cp $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties $SR_CONFIG
  sed -i '' "s/listeners=http:\/\/0.0.0.0:8081/listeners=http:\/\/0.0.0.0:$SR_LISTENER/g" $SR_CONFIG
  # Avoid clash between two local SR instances
  sed -i '' 's/kafkastore.connection.url=localhost:2181/#kafkastore.connection.url=localhost:2181/g' $SR_CONFIG
  cat $DELTA_CONFIGS_DIR/schema-registry-ccloud.delta >> $SR_CONFIG
  echo "Starting Confluent Schema Registry for Confluent Cloud and sleeping 40 seconds"
  schema-registry-start $SR_CONFIG > $CONFLUENT_CURRENT/schema-registry/schema-registry-ccloud.stdout 2>&1 &
  sleep 40
  ccloud topic describe _schemas
  if [[ $? == 1 ]]; then
    echo "ERROR: Schema Registry could not create topic '_schemas' in Confluent Cloud. Please troubleshoot"
    exit
  fi
fi

# Produce to topic pageviews in local cluster
kafka-topics --zookeeper localhost:2181 --create --topic pageviews --partitions 12 --replication-factor 1
echo "ksql-datagen quickstart=pageviews format=avro topic=pageviews maxInterval=100 schemaRegistryUrl=$SR_URL propertiesFile=$SR_PROPERTIES"
ksql-datagen quickstart=pageviews format=avro topic=pageviews maxInterval=100 schemaRegistryUrl=$SR_URL propertiesFile=$SR_PROPERTIES &>/dev/null &
sleep 5

# Register the same schema for the replicated topic pageviews.replica as was created for the original topic pageviews
#curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{\"schema\": $(curl -s http://localhost:8085/subjects/pageviews-value/versions/latest | jq '.schema')}" http://localhost:8085/subjects/pageviews.replica-value/versions 

# Produce to topic users in CCloud cluster
ccloud topic create users
KSQL_DATAGEN_PROPERTIES=$CONFLUENT_CURRENT/ksql-server/ksql-datagen.properties
cp $DELTA_CONFIGS_DIR/ksql-datagen.delta $KSQL_DATAGEN_PROPERTIES
ksql-datagen quickstart=users format=avro topic=users maxInterval=1000 schemaRegistryUrl=$SR_URL propertiesFile=$KSQL_DATAGEN_PROPERTIES &>/dev/null &

# Stop the Connect that starts with Confluent CLI to run Replicator that includes its own Connect workers
jps | grep ConnectDistributed | awk '{print $1;}' | xargs kill -9
jps | grep ReplicatorApp | awk '{print $1;}' | xargs kill -9

# Replicate local topic `pageviews` to Confluent Cloud topic `pageviews`
ccloud topic create pageviews
PRODUCER_PROPERTIES=$CONFLUENT_CURRENT/connect/replicator-to-ccloud-producer.properties
cp $DELTA_CONFIGS_DIR/replicator-to-ccloud-producer.delta $PRODUCER_PROPERTIES
CONSUMER_PROPERTIES=$CONFLUENT_CURRENT/connect/replicator-to-ccloud-consumer.properties
echo "bootstrap.servers=localhost:9092" > $CONSUMER_PROPERTIES
REPLICATOR_PROPERTIES=$CONFLUENT_CURRENT/connect/replicator-to-ccloud.properties
echo "topic.whitelist=pageviews" > $REPLICATOR_PROPERTIES
#echo "topic.rename.format=\${topic}.replica" >> $REPLICATOR_PROPERTIES
echo "Starting Confluent Replicator and sleeping 60 seconds"
replicator --cluster.id replicator-to-ccloud --consumer.config $CONSUMER_PROPERTIES --producer.config $PRODUCER_PROPERTIES --replication.config $REPLICATOR_PROPERTIES > $CONFLUENT_CURRENT/connect/replicator-to-ccloud.stdout 2>&1 &
sleep 60

# KSQL Server runs locally and connects to Confluent Cloud
jps | grep KsqlServerMain | awk '{print $1;}' | xargs kill -9
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
while read -r line
do
  echo "ksql.$line" >> $KSQL_SERVER_CONFIG
done < "$SR_PROPERTIES_FILE"
echo "Starting KSQL Server for Confluent Cloud and sleeping 25 seconds"
ksql-server-start $KSQL_SERVER_CONFIG > $CONFLUENT_CURRENT/ksql-server/ksql-server-ccloud.stdout 2>&1 &
sleep 25
ksql http://localhost:$KSQL_LISTENER <<EOF
run script 'ksql.commands';
exit ;
EOF

# Confluent Control Center runs locally, monitors Confluent Cloud, and uses Confluent Cloud cluster as the backstore
if is_ce; then
  C3_CONFIG=$CONFLUENT_CURRENT/control-center/control-center-ccloud.properties
  cp $CONFLUENT_HOME/etc/confluent-control-center/control-center-production.properties $C3_CONFIG
  # Stop the Control Center that starts with Confluent CLI to run Control Center to CCloud
  jps | grep ControlCenter | awk '{print $1;}' | xargs kill -9
  cat $DELTA_CONFIGS_DIR/control-center-ccloud.delta >> $C3_CONFIG
  echo "confluent.controlcenter.connect.cluster=localhost:8083" >> $C3_CONFIG
  echo "confluent.controlcenter.data.dir=$CONFLUENT_CURRENT/control-center/data-ccloud" >> $C3_CONFIG
  echo "confluent.controlcenter.ksql.url=http://localhost:$KSQL_LISTENER" >> $C3_CONFIG
  # Workaround for MMA-3564
  echo "confluent.metrics.topic.max.message.bytes=8388608" >> $C3_CONFIG
  control-center-start $C3_CONFIG > $CONFLUENT_CURRENT/control-center/control-center-ccloud.stdout 2>&1 &
fi
while read -r line
do
  echo "confluent.controlcenter.$line" >> $C3_CONFIG
done < "$SR_PROPERTIES_FILE"

sleep 10
