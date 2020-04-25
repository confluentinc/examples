#!/bin/bash

# Source library
. ../utils/helper.sh

echo ====== Verifying prerequisites
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
printf "Done\n"

if ! check_cp ; then
  echo "This demo uses Confluent Replicator which requires Confluent Platform, however this host is running Confluent Community Software. Exiting"
  exit 1
fi
printf "\n"

echo ====== Cleaning up previous run
./stop.sh
printf "\nDone with cleanup\n\n"

echo ====== Installing kafka-connect-datagen
confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:$KAFKA_CONNECT_DATAGEN_VERSION
printf "\n"

echo ====== Starting local Kafka Connect
confluent local start connect
CONFLUENT_CURRENT=`confluent local current | tail -1`
printf "\n"

echo ====== Generate CCloud configurations
SCHEMA_REGISTRY_CONFIG_FILE=$CONFIG_FILE
./ccloud-generate-cp-configs.sh $CONFIG_FILE $SCHEMA_REGISTRY_CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta
printf "\n"

echo ====== Set current Confluent Cloud 
# Set Kafka cluster and service account
ccloud_cli_set_kafka_cluster_use $CLOUD_KEY $CONFIG_FILE || exit 1
serviceAccount=$(ccloud_cli_get_service_account $CLOUD_KEY $CONFIG_FILE) || exit 1
printf "\n"

echo ====== Validate Schema Registry credentials
# Validate credentials to Confluent Cloud Schema Registry
validate_confluent_cloud_schema_registry $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL || exit 1
printf "Done\n\n"

echo ====== Start local Confluent Control Center to monitor Cloud and local clusters
# For the KSQL Server backed to Confluent Cloud, set the REST port, instead of the default 8088 which is already in use by the local KSQL server
KSQL_LISTENER=8089
# For the Connect cluster backed to Confluent Cloud, set the REST port, instead of the default 8083 which is already in use by the local connect cluster
CONNECT_REST_PORT=8087

create_c3_acls $serviceAccount
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
  ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic _confluent-controlcenter --prefix
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic _confluent-controlcenter --prefix
  control-center-start $C3_CONFIG > $CONFLUENT_CURRENT/control-center/control-center-ccloud.stdout 2>&1 &
fi
printf "\n"

echo ====== Create topic pageviews in local cluster
kafka-topics --bootstrap-server localhost:9092 --create --topic pageviews --partitions 6 --replication-factor 1
sleep 20
printf "\n"

echo ====== Submit datagen connector for pageviews 
. ./connectors/submit_datagen_pageviews_config.sh
printf "\n\n"

echo ====== Start Local Connect cluster that connects to CCloud Kafka
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
create_connect_topics_and_acls $serviceAccount
export CLASSPATH=$(find ${CONFLUENT_HOME}/share/java/kafka-connect-replicator/replicator-rest-extension-*)
connect-distributed $CONNECT_CONFIG > $CONFLUENT_CURRENT/connect/connect-ccloud.stdout 2>&1 &
MAX_WAIT=40
echo "Waiting up to $MAX_WAIT seconds for the connect worker that connects to Confluent Cloud to start"
retry $MAX_WAIT check_connect_up_logFile $CONFLUENT_CURRENT/connect/connect-ccloud.stdout || exit 1
printf "\n\n"

echo ====== Create topic users and set ACLs in CCloud cluster
ccloud kafka topic create users
ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic users
printf "\n"

echo ====== submit Datagen connector for users
. ./connectors/submit_datagen_users_config.sh
printf "\n"

echo ====== Replicate local topic 'pageviews' to Confluent Cloud topic 'pageviews'
ccloud kafka topic create pageviews
ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic pageviews
printf "\n"

echo ====== Starting Replicator and sleeping 60 seconds
. ./connectors/submit_replicator_config.sh
sleep 60
printf "\n"

echo ====== Creating Confluent Cloud KSQL application
./create_ksql_app.sh || exit 1
printf "\n"

printf "\nDONE! Connect to your Confluent Cloud UI or Confluent Control Center at http://localhost:9021\n"
