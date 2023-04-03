#!/bin/bash

# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

NAME=`basename "$0"`

echo ====== Verifying prerequisites
validate_version_confluent_cli_v2 \
  && print_pass "confluent CLI version ok" \
  || exit 1
check_env \
  && print_pass "Confluent Platform installed" \
  || exit 1
check_cp \
  || exit_with_error -c $? -n $NAME -l $LINENO -m "This example uses Confluent Replicator which requires Confluent Platform, however this host is running Confluent Community Software"
check_running_cp ${CONFLUENT} \
  && print_pass "Confluent Platform version ${CONFLUENT} ok" \
  || exit 1
check_jq \
  && print_pass "jq installed" \
  || exit 1
ccloud::validate_version_ccloud_cli 1.7.0 \
  && print_pass "ccloud version ok" \
  || exit 1
ccloud::validate_logged_in_ccloud_cli \
  && print_pass "logged into ccloud CLI" \
  || exit 1

export EXAMPLE="original-hybrid-cloud-tarball"

echo ====== Create new Confluent Cloud stack
ccloud::prompt_continue_ccloud_demo || exit 1
ccloud::create_ccloud_stack true
SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
if [[ "$SERVICE_ACCOUNT_ID" == "" ]]; then
  echo "ERROR: Could not determine SERVICE_ACCOUNT_ID from 'ccloud kafka cluster list'. Please troubleshoot, destroy stack, and try again to create the stack."
  exit 1
fi
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
export CONFIG_FILE=$CONFIG_FILE
ccloud::validate_ccloud_config $CONFIG_FILE \
  && print_pass "$CONFIG_FILE ok" \
  || exit 1

echo ====== Generate Confluent Cloud configurations
./ccloud-generate-cp-configs.sh $CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta
printf "\n"

# Pre-flight check of Confluent Cloud credentials specified in $CONFIG_FILE
MAX_WAIT=720
echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud ksqlDB cluster to be UP"
retry $MAX_WAIT ccloud::validate_ccloud_ksqldb_endpoint_ready $KSQLDB_ENDPOINT || exit 1
ccloud::validate_ccloud_stack_up $CLOUD_KEY $CONFIG_FILE || exit 1

echo ====== Installing kafka-connect-datagen
confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:$KAFKA_CONNECT_DATAGEN_VERSION
printf "\n"

echo ====== Starting local ZooKeeper, Kafka Broker, Schema Registry, Connect
confluent local services zookeeper start
sleep 2

# Start local Kafka with Confluent Metrics Reporter configured for Confluent Cloud
CONFLUENT_CURRENT=`confluent local current 2>&1 | tail -1`
mkdir -p $CONFLUENT_CURRENT/kafka
KAFKA_CONFIG=$CONFLUENT_CURRENT/kafka/server.properties
cp $CONFLUENT_HOME/etc/kafka/server.properties $KAFKA_CONFIG
cat $DELTA_CONFIGS_DIR/metrics-reporter.delta >> $KAFKA_CONFIG
kafka-server-start $KAFKA_CONFIG > $CONFLUENT_CURRENT/kafka/server.stdout 2>&1 &
echo $! > $CONFLUENT_CURRENT/kafka/kafka.pid
echo "Waiting 30s for the local Kafka broker to be UP"
sleep 30

confluent local services connect start
printf "\n"

echo ====== Set current Confluent Cloud 
# Set Kafka cluster and service account
ccloud::set_kafka_cluster_use_from_api_key $CLOUD_KEY || exit 1
serviceAccount=$(ccloud::get_service_account $CLOUD_KEY) || exit 1
printf "\n"

echo ====== Validate Schema Registry credentials
# Validate credentials to Confluent Cloud Schema Registry
ccloud::validate_schema_registry_up $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL || exit 1
printf "Done\n\n"

echo ====== Start local Confluent Control Center to monitor Cloud and local clusters
# For the Connect cluster backed to Confluent Cloud, set the REST port, instead of the default 8083 which is already in use by the local connect cluster
CONNECT_REST_PORT=8087

ccloud::create_acls_control_center $serviceAccount
if check_cp; then
  mkdir -p $CONFLUENT_CURRENT/control-center
  C3_CONFIG=$CONFLUENT_CURRENT/control-center/control-center-ccloud.properties
  cp $CONFLUENT_HOME/etc/confluent-control-center/control-center-production.properties $C3_CONFIG
  # Stop the Control Center that starts with Confluent CLI to run Control Center to Confluent Cloud
  jps | grep ControlCenter | awk '{print $1;}' | xargs kill -9
  cat $DELTA_CONFIGS_DIR/control-center-ccloud.delta >> $C3_CONFIG

cat <<EOF >> $C3_CONFIG
# Kafka clusters
confluent.controlcenter.kafka.local.bootstrap.servers=localhost:9092
confluent.controlcenter.kafka.cloud.bootstrap.servers=$BOOTSTRAP_SERVERS
confluent.controlcenter.kafka.cloud.sasl.mechanism=PLAIN
confluent.controlcenter.kafka.cloud.security.protocol=SASL_SSL
confluent.controlcenter.kafka.cloud.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"$CLOUD_KEY\" password=\"$CLOUD_SECRET\";

# Connect clusters
confluent.controlcenter.connect.local.cluster=http://localhost:8083
confluent.controlcenter.connect.cloud.cluster=http://localhost:$CONNECT_REST_PORT

confluent.controlcenter.data.dir=$CONFLUENT_CURRENT/control-center/data-ccloud
# Workaround for MMA-3564
confluent.metrics.topic.max.message.bytes=8388608
EOF

  ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic _confluent-controlcenter --prefix
  ccloud kafka acl create --allow --service-account $serviceAccount --operation READ --topic _confluent-controlcenter --prefix
  control-center-start $C3_CONFIG > $CONFLUENT_CURRENT/control-center/control-center-ccloud.stdout 2>&1 &
fi
printf "\n"

echo ====== Create topic pageviews in local cluster
kafka-topics --bootstrap-server localhost:9092 --create --topic pageviews --partitions 6 --replication-factor 1
sleep 20
printf "\n"

echo ====== Deploying kafka-connect-datagen for pageviews
source ./connectors/submit_datagen_pageviews_config.sh
printf "\n\n"

echo ====== Start Local Connect cluster that connects to Confluent Cloud Kafka
mkdir -p $CONFLUENT_CURRENT/connect
CONNECT_CONFIG=$CONFLUENT_CURRENT/connect/connect-ccloud.properties
cp $CONFLUENT_CURRENT/connect/connect.properties $CONNECT_CONFIG
cat $DELTA_CONFIGS_DIR/connect-ccloud.delta >> $CONNECT_CONFIG
cat <<EOF >> $CONNECT_CONFIG
rest.port=$CONNECT_REST_PORT
rest.advertised.name=connect-cloud
rest.hostname=connect-cloud
group.id=connect-cloud
config.storage.topic=connect-demo-configs
offset.storage.topic=connect-demo-offsets
status.storage.topic=connect-demo-statuses
EOF
ccloud::create_acls_connect_topics $serviceAccount
export CLASSPATH=$(find ${CONFLUENT_HOME}/share/java/kafka-connect-replicator/replicator-rest-extension-*)
connect-distributed $CONNECT_CONFIG > $CONFLUENT_CURRENT/connect/connect-ccloud.stdout 2>&1 &
MAX_WAIT=240
echo "Waiting up to $MAX_WAIT seconds for the connect worker that connects to Confluent Cloud to start"
retry $MAX_WAIT check_connect_up_logFile $CONFLUENT_CURRENT/connect/connect-ccloud.stdout || exit 1
printf "\n\n"

echo ====== Create topic users and set ACLs in Confluent Cloud cluster
ccloud kafka topic create users
ccloud kafka acl create --allow --service-account $serviceAccount --operation WRITE --topic users
printf "\n"

echo ====== Deploying kafka-connect-datagen for users
source ./connectors/submit_datagen_users_config.sh
printf "\n"

echo ====== Replicate local topic 'pageviews' to Confluent Cloud topic 'pageviews'
# No need to pre-create topic pageviews in Confluent Cloud because Replicator will do this automatically
ccloud::create_acls_replicator $serviceAccount pageviews
printf "\n"

echo ====== Starting Replicator
source ./connectors/submit_replicator_config.sh
MAX_WAIT=60
printf "\nWaiting up to $MAX_WAIT seconds for the topic pageviews to be created in Confluent Cloud"
retry $MAX_WAIT ccloud::validate_topic_exists pageviews || exit 1
printf "\nWaiting up to $MAX_WAIT seconds for the subject pageviews-value to be created in Confluent Cloud Schema Registry"
retry $MAX_WAIT ccloud::validate_subject_exists "pageviews-value" $SCHEMA_REGISTRY_URL $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO || exit 1
printf "\n\n"

echo ====== Creating Confluent Cloud ksqlDB application
./create_ksqldb_app.sh || exit 1
printf "\n"

printf "\nDONE! Connect to your Confluent Cloud UI at https://confluent.cloud/ or Confluent Control Center at http://localhost:9021\n"
echo
echo "Local client configuration file written to $CONFIG_FILE"
echo

echo
echo "To stop this example and destroy Confluent Cloud resources run ->"
echo "    ./stop.sh $CONFIG_FILE"
echo

echo
ENVIRONMENT=$(ccloud environment list | grep ccloud-stack-$SERVICE_ACCOUNT_ID | tr -d '\*' | awk '{print $1;}')
echo "Tip: 'ccloud' CLI has been set to the new environment $ENVIRONMENT"
