#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_jq || exit 1
check_running_cp ${CP_VERSION_MAJOR} || exit 1

. ./config.sh
check_ccloud_config $CONFIG_FILE || exit

if ! check_cp ; then
  echo "This demo uses Confluent Replicator which requires Confluent Platform, however this host is running Confluent Community Software. Exiting"
  exit 1
fi

./stop.sh

confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:0.2.0
confluent local start connect
CONFLUENT_CURRENT=`confluent local current | tail -1`

if [[ "${USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY}" == true ]]; then
  SCHEMA_REGISTRY_CONFIG_FILE=$CONFIG_FILE
else
  SCHEMA_REGISTRY_CONFIG_FILE=schema_registry.config
fi
./ccloud-generate-cp-configs.sh $CONFIG_FILE $SCHEMA_REGISTRY_CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

if [[ "$USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY" == true ]]; then
  # Use Confluent Cloud Schema Registry
  validate_confluent_cloud_schema_registry $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL || exit 1
else
  mkdir -p $CONFLUENT_CURRENT/schema-registry
  # Confluent Schema Registry runs locally and connects to Confluent Cloud
  # Set this new Schema Registry listener to port $SR_LISTENER instead of the default 8081 which is already in use
  SR_LISTENER=8085
  SCHEMA_REGISTRY_URL=http://localhost:$SR_LISTENER
  SR_CONFIG=$CONFLUENT_CURRENT/schema-registry/schema-registry-ccloud.properties
  cp $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties $SR_CONFIG
  sed -i '' "s/listeners=http:\/\/0.0.0.0:8081/listeners=http:\/\/0.0.0.0:$SR_LISTENER/g" $SR_CONFIG
  # Avoid clash between two local SR instances
  sed -i '' 's/kafkastore.connection.url=localhost:2181/#kafkastore.connection.url=localhost:2181/g' $SR_CONFIG
  cat $DELTA_CONFIGS_DIR/schema-registry-ccloud.delta >> $SR_CONFIG
  echo -e "\nStarting Confluent Schema Registry to Confluent Cloud and sleeping 40 seconds"
  schema-registry-start $SR_CONFIG > $CONFLUENT_CURRENT/schema-registry/schema-registry-ccloud.stdout 2>&1 &
  sleep 40
  kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $CONFIG_FILE | tail -1` --command-config $CONFIG_FILE --describe --topic _schemas
  if [[ $? == 1 ]]; then
    echo "ERROR: Schema Registry could not create topic '_schemas' in Confluent Cloud. Please troubleshoot"
    exit
  fi
fi

# For the KSQL Server backed to Confluent Cloud, set the REST port, instead of the default 8088 which is already in use by the local KSQL server
KSQL_LISTENER=8089
# For the Connect cluster backed to Confluent Cloud, set the REST port, instead of the default 8083 which is already in use by the local connect cluster
CONNECT_REST_PORT=8087

# Confluent Control Center runs locally, monitors Confluent Cloud, and uses Confluent Cloud cluster as the backstore
if check_cp; then
  mkdir -p $CONFLUENT_CURRENT/control-center
  C3_CONFIG=$CONFLUENT_CURRENT/control-center/control-center-ccloud.properties
  cp $CONFLUENT_HOME/etc/confluent-control-center/control-center-production.properties $C3_CONFIG
  # Stop the Control Center that starts with Confluent CLI to run Control Center to CCloud
  jps | grep ControlCenter | awk '{print $1;}' | xargs kill -9
  cat $DELTA_CONFIGS_DIR/control-center-ccloud.delta >> $C3_CONFIG
  echo "confluent.controlcenter.connect.cluster=http://localhost:$CONNECT_REST_PORT" >> $C3_CONFIG
  echo "confluent.controlcenter.data.dir=$CONFLUENT_CURRENT/control-center/data-ccloud" >> $C3_CONFIG
  echo "confluent.controlcenter.ksql.url=http://localhost:$KSQL_LISTENER" >> $C3_CONFIG
  # Workaround for MMA-3564
  echo "confluent.metrics.topic.max.message.bytes=8388608" >> $C3_CONFIG
  control-center-start $C3_CONFIG > $CONFLUENT_CURRENT/control-center/control-center-ccloud.stdout 2>&1 &
fi

# Produce to topic pageviews in local cluster
kafka-topics --zookeeper localhost:2181 --create --topic pageviews --partitions 6 --replication-factor 1
# Use kafka-connect-datagen instead of ksql-datagen due to KSQL-2278
#echo "ksql-datagen quickstart=pageviews format=avro topic=pageviews maxInterval=100 schemaRegistryUrl=$SCHEMA_REGISTRY_URL propertiesFile=$SR_PROPERTIES"
#ksql-datagen quickstart=pageviews format=avro topic=pageviews maxInterval=100 schemaRegistryUrl=$SCHEMA_REGISTRY_URL propertiesFile=$SR_PROPERTIES &>/dev/null &
sleep 20
. ./connectors/submit_datagen_pageviews_config.sh
#sleep 5

# Register the same schema for the replicated topic pageviews.replica as was created for the original topic pageviews
#curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{\"schema\": $(curl -s http://localhost:8085/subjects/pageviews-value/versions/latest | jq '.schema')}" http://localhost:8085/subjects/pageviews.replica-value/versions 

# Start Connect that connects to CCloud cluster
mkdir -p $CONFLUENT_CURRENT/connect
CONNECT_CONFIG=$CONFLUENT_CURRENT/connect/connect-ccloud.properties
cp $CONFLUENT_CURRENT/connect/connect.properties $CONNECT_CONFIG
cat $DELTA_CONFIGS_DIR/connect-ccloud.delta >> $CONNECT_CONFIG
cat <<EOF >> $CONNECT_CONFIG
rest.port=$CONNECT_REST_PORT
rest.advertised.name=connect-cloud
rest.hostname=connect-cloud
group.id=connect-cloud
EOF
export CLASSPATH=$(find ${CONFLUENT_HOME}/share/java/kafka-connect-replicator/replicator-rest-extension-*)
connect-distributed $CONNECT_CONFIG > $CONFLUENT_CURRENT/connect/connect-ccloud.stdout 2>&1 &
sleep 40

# Produce to topic users in CCloud cluster
kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $CONFIG_FILE | tail -1` --command-config $CONFIG_FILE --topic users --create --replication-factor 3 --partitions 6
# Use kafka-connect-datagen instead of ksql-datagen due to KSQL-2278
#KSQL_DATAGEN_PROPERTIES=$CONFLUENT_CURRENT/ksql-server/ksql-datagen.properties
#cp $DELTA_CONFIGS_DIR/ksql-datagen.delta $KSQL_DATAGEN_PROPERTIES
#ksql-datagen quickstart=users format=avro topic=users maxInterval=1000 schemaRegistryUrl=$SCHEMA_REGISTRY_URL propertiesFile=$KSQL_DATAGEN_PROPERTIES &>/dev/null &
. ./connectors/submit_datagen_users_config.sh

# Stop the Connect that starts with Confluent CLI to run Replicator that includes its own Connect workers
#jps | grep ConnectDistributed | awk '{print $1;}' | xargs kill -9
#jps | grep ReplicatorApp | awk '{print $1;}' | xargs kill -9

# Replicate local topic 'pageviews' to Confluent Cloud topic 'pageviews'
kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $CONFIG_FILE | tail -1` --command-config $CONFIG_FILE --topic pageviews --create --replication-factor 3 --partitions 6
. ./connectors/submit_replicator_config.sh
echo -e "\nStarting Replicator and sleeping 60 seconds"
sleep 60

# KSQL Server runs locally and connects to Confluent Cloud
if [[ "${USE_CONFLUENT_CLOUD_KSQL}" == false ]]; then
  jps | grep KsqlServerMain | awk '{print $1;}' | xargs kill -9
  mkdir -p $CONFLUENT_CURRENT/ksql-server
  KSQL_SERVER_CONFIG=$CONFLUENT_CURRENT/ksql-server/ksql-server-ccloud.properties
  cp $DELTA_CONFIGS_DIR/ksql-server-ccloud.delta $KSQL_SERVER_CONFIG
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
fi

echo -e "\nDONE! Connect to your Confluent Cloud UI or Confluent Control Center at http://localhost:9021\n"

if [[ "${USE_CONFLUENT_CLOUD_KSQL}" == true ]]; then
  echo -e "\nSince you are running Confluent Cloud KSQL, use the Cloud UI to copy/paste the KSQL queries from the 'ksql.commands' file\n"
fi

