#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_jq || exit 1
check_running_cp ${CONFLUENT_SHORT} || exit 1

# File with Confluent Cloud configuration parameters: example template
#   $ cat ~/.ccloud/config
#   bootstrap.servers=<BROKER ENDPOINT>
#   ssl.endpoint.identification.algorithm=https
#   security.protocol=SASL_SSL
#   sasl.mechanism=PLAIN
#   sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
#   # Confluent Cloud Schema Registry
#   basic.auth.credentials.source=USER_INFO
#   schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
#   schema.registry.url=https://<SR ENDPOINT>
#   # Confluent Cloud KSQL
#   ksql.endpoint=https://<KSQL ENDPOINT>
#   ksql.basic.auth.user.info=<KSQL API KEY>:<KSQL API SECRET>
export CONFIG_FILE=~/.ccloud/config

check_ccloud_config $CONFIG_FILE || exit 1
check_ccloud_version 0.264.0 || exit 1
check_ccloud_logged_in || exit 1

if ! check_cp ; then
  echo "This demo uses Confluent Replicator which requires Confluent Platform, however this host is running Confluent Community Software. Exiting"
  exit 1
fi

./stop.sh

confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:$KAFKA_CONNECT_DATAGEN_VERSION
confluent local start connect
CONFLUENT_CURRENT=`confluent local current | tail -1`

#################################################################
# Generate CCloud configurations
#################################################################

SCHEMA_REGISTRY_CONFIG_FILE=$CONFIG_FILE
./ccloud-generate-cp-configs.sh $CONFIG_FILE $SCHEMA_REGISTRY_CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

# Set Kafka cluster
ccloud_cli_set_kafka_cluster_use $CLOUD_KEY $CONFIG_FILE || exit 1

# Validate credentials to Confluent Cloud Schema Registry
validate_confluent_cloud_schema_registry $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL || exit 1

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
sleep 20
. ./connectors/submit_datagen_pageviews_config.sh
#sleep 5

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
serviceAccount=$(ccloud_cli_get_service_account $CLOUD_KEY $CONFIG_FILE) || exit 1
create_connect_topics_and_acls $serviceAccount
export CLASSPATH=$(find ${CONFLUENT_HOME}/share/java/kafka-connect-replicator/replicator-rest-extension-*)
connect-distributed $CONNECT_CONFIG > $CONFLUENT_CURRENT/connect/connect-ccloud.stdout 2>&1 &
MAX_WAIT=40
echo "Waiting up to $MAX_WAIT seconds for the connect worker that connects to Confluent Cloud to start"
retry $MAX_WAIT check_connect_up_logFile $CONFLUENT_CURRENT/connect/connect-ccloud.stdout || exit 1

# Produce to topic users in CCloud cluster
ccloud kafka topic create users
. ./connectors/submit_datagen_users_config.sh

# Stop the Connect that starts with Confluent CLI to run Replicator that includes its own Connect workers
#jps | grep ConnectDistributed | awk '{print $1;}' | xargs kill -9
#jps | grep ReplicatorApp | awk '{print $1;}' | xargs kill -9

# Replicate local topic 'pageviews' to Confluent Cloud topic 'pageviews'
ccloud kafka topic create pageviews
. ./connectors/submit_replicator_config.sh
echo -e "\nStarting Replicator and sleeping 60 seconds"
sleep 60

# Confluent Cloud KSQL application
./create_ksql_app.sh || exit 1

echo -e "\nDONE! Connect to your Confluent Cloud UI or Confluent Control Center at http://localhost:9021\n"
