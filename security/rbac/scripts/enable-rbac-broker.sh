#!/bin/bash


################################################################################
# Overview
################################################################################
#
################################################################################

# Source library
source ../../../utils/helper.sh
source ./rbac_lib.sh

check_env || exit 1
validate_version_confluent_cli_v2 || exit 1
check_jq || exit 1

##################################################
# Initialize
##################################################

source ../config/local-demo.env
ORIGINAL_CONFIGS_DIR=/tmp/original_configs
DELTA_CONFIGS_DIR=../delta_configs
FILENAME=server.properties
create_temp_configs $CONFLUENT_HOME/etc/kafka/$FILENAME $ORIGINAL_CONFIGS_DIR/$FILENAME $DELTA_CONFIGS_DIR/${FILENAME}.delta
confluent local services kafka start

echo -e "Sleeping 10 seconds before login"
sleep 10

# Log in to Metadata Server (MDS)
login_mds $MDS

##################################################
# Administrative Functions
# - Grant principal User:$USER_ADMIN_SYSTEM the SystemAdmin role to the Kafka cluster
##################################################

get_cluster_id_kafka
echo -e "\n# Grant principal User:$USER_ADMIN_SYSTEM the SystemAdmin role to the Kafka cluster"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_SYSTEM --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_SYSTEM --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for User:$USER_ADMIN_SYSTEM"
echo "confluent iam rolebinding list --principal User:$USER_ADMIN_SYSTEM --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_ADMIN_SYSTEM --kafka-cluster-id $KAFKA_CLUSTER_ID

##################################################
# Topics: create, producer, consume
# - Grant principal User:$USER_CLIENT_A the ResourceOwner role to Topic:$TOPIC1
# - Create topic $TOPIC1
# - List topics, it should show only topic $TOPIC1
# - Produce to topic $TOPIC1
# - Grant principal User:$USER_CLIENT_A the DeveloperRead role to Group:console-consumer- prefix
# - Consume from topic $TOPIC1 from RBAC endpoint
# - Consume from topic $TOPIC1 from PLAINTEXT endpoint
##################################################
echo -e "\n# Try to create topic $TOPIC1, before authorization (should fail)"
echo "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC1 --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/client.properties.delta"
OUTPUT=$(kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC1 --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/client.properties.delta 2>&1)
if [[ $OUTPUT =~ "org.apache.kafka.common.errors.TopicAuthorizationException" ]]; then
  echo "PASS: Topic creation failed due to org.apache.kafka.common.errors.TopicAuthorizationException (expected because User:$USER_CLIENT_A is not allowed to create topics)"
else
  echo -e "FAIL: Something went wrong, check output:\n$OUTPUT"
fi

echo -e "\n# Grant principal User:$USER_CLIENT_A the ResourceOwner role to Topic:$TOPIC1"
echo "confluent iam rolebinding create --principal User:$USER_CLIENT_A --role ResourceOwner --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CLIENT_A --role ResourceOwner --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Try to create topic $TOPIC1, after authorization (should pass)"
echo "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC1 --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/client.properties.delta"
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC1 --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/client.properties.delta

echo -e "\n# List topics, it should show only topic $TOPIC1"
echo "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --list --command-config $DELTA_CONFIGS_DIR/client.properties.delta"
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --list --command-config $DELTA_CONFIGS_DIR/client.properties.delta

##################################################
# Client authentication:
# - In production: use either Kerberos or mTLS for client authentication; do not use the token service
#   which is meant only for internal communication between Confluent components.
# - In this demo: for simplicity, the producer and consumer use the token service for client authentication,
#   e.g. client.properties.delta uses 'sasl.mechanism=OAUTHBEARER', but do not do this in production.
##################################################

NUM_MESSAGES=10
MESSAGE=""
for i in $(seq 1 $NUM_MESSAGES); do
  if [ "$i" -ne "1" ]; then
    MESSAGE+=$'\n'
  fi
  MESSAGE+="$i,$i"
done
echo $MESSAGE
echo -e "\n# Produce $NUM_MESSAGES messages to topic $TOPIC1"
set -x
echo -e "${MESSAGE}" | confluent local services kafka produce $TOPIC1 --bootstrap-server $BOOTSTRAP_SERVER --producer.config $DELTA_CONFIGS_DIR/client.properties.delta --property parse.key=true --property key.separator=,
set +x

echo -e "\n# Consume from topic $TOPIC1 from RBAC endpoint (should fail)"
echo "confluent local services kafka consume $TOPIC1 --bootstrap-server $BOOTSTRAP_SERVER --consumer.config $DELTA_CONFIGS_DIR/client.properties.delta --from-beginning --property print.key=true --max-messages $NUM_MESSAGES"
OUTPUT=$(confluent local services kafka consume $TOPIC1 --bootstrap-server $BOOTSTRAP_SERVER --consumer.config $DELTA_CONFIGS_DIR/client.properties.delta --from-beginning --property print.key=true --max-messages $NUM_MESSAGES 2>&1)
if [[ $OUTPUT =~ "org.apache.kafka.common.errors.GroupAuthorizationException" ]]; then
  echo "PASS: Consume failed due to org.apache.kafka.common.errors.GroupAuthorizationException (expected because User:$USER_CLIENT_A is not allowed access to consumer groups)"
else
  echo -e "FAIL: Something went wrong, check output:\n$OUTPUT"
fi

echo -e "#\n Grant principal User:$USER_CLIENT_A the DeveloperRead role to Group:console-consumer- prefix"
echo "confluent iam rolebinding create --principal User:$USER_CLIENT_A --role DeveloperRead --resource Group:console-consumer- --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CLIENT_A --role DeveloperRead --resource Group:console-consumer- --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Consume from topic $TOPIC1 from RBAC endpoint (should pass)"
echo "confluent local services kafka consume $TOPIC1 --bootstrap-server $BOOTSTRAP_SERVER --consumer.config $DELTA_CONFIGS_DIR/client.properties.delta --from-beginning --property print.key=true --max-messages $NUM_MESSAGES"
confluent local services kafka consume $TOPIC1 --bootstrap-server $BOOTSTRAP_SERVER --consumer.config $DELTA_CONFIGS_DIR/client.properties.delta --from-beginning --property print.key=true --max-messages $NUM_MESSAGES

echo -e "\n# Consume from topic $TOPIC1 from PLAINTEXT endpoint"
echo "confluent local services kafka consume $TOPIC1 --bootstrap-server $BOOTSTRAP_SERVER_PLAINTEXT --from-beginning --property print.key=true --max-messages $NUM_MESSAGES"
confluent local services kafka consume $TOPIC1 --bootstrap-server $BOOTSTRAP_SERVER_PLAINTEXT --from-beginning --property print.key=true --max-messages $NUM_MESSAGES


##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/kafka/$FILENAME $ORIGINAL_CONFIGS_DIR/$FILENAME $SAVE_CONFIGS_DIR/${FILENAME}.rbac
