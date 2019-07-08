#!/bin/bash


################################################################################
# Overview
################################################################################
#
################################################################################

# Source library
. ../../../utils/helper.sh
. ./rbac_lib.sh

check_env || exit 1
check_cli_v2 || exit 1
check_jq || exit 1

##################################################
# Initialize
##################################################

. ../config/local-demo.cfg
ORIGINAL_CONFIGS_DIR=../original_configs
DELTA_CONFIGS_DIR=../delta_configs
create_temp_configs $CONFLUENT_HOME/etc/kafka/server.properties $ORIGINAL_CONFIGS_DIR/server.properties $DELTA_CONFIGS_DIR/server.properties.delta
confluent local start kafka

# Log in to Metadata Server (MDS)
login_mds $MDS

##################################################
# Administrative Functions
# - Grant the principal User:$ADMIN_SYSTEM the SystemAdmin role # access to different service clusters
##################################################

# Grant the principal User:$ADMIN_SYSTEM the SystemAdmin role # access to different service clusters
get_cluster_id_kafka
echo -e "\n# Grant the principal User:$ADMIN_SYSTEM to the SystemAdmin role access to the Kafka cluster"
echo "confluent iam rolebinding create --principal User:$ADMIN_SYSTEM --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_SYSTEM --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for User:$ADMIN_SYSTEM"
echo "confluent iam rolebinding list --principal User:$ADMIN_SYSTEM --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$ADMIN_SYSTEM --kafka-cluster-id $KAFKA_CLUSTER_ID

##################################################
# Topics: create, producer, consume
# - Grant the principal User:$CLIENT to the ResourceOwner role for Topic:$TOPIC
# - Create topic $TOPIC
# - List topics, it should show only topic $TOPIC
# - Produce to topic $TOPIC
# - Create a role binding to the resource Group:console-consumer-
# - Consume from topic $TOPIC from RBAC endpoint
# - Consume from topic $TOPIC from PLAINTEXT endpoint
##################################################
TOPIC=test-topic-1
echo -e "\n# Create a topic called $TOPIC"

echo -e "\n# Try to create topic $TOPIC, before authorization (should fail)"
echo "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/client.properties.delta"
OUTPUT=$(kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/client.properties.delta)
if [[ $OUTPUT =~ "org.apache.kafka.common.errors.TopicAuthorizationException" ]]; then
  echo "PASS: Topic creation failed due to org.apache.kafka.common.errors.TopicAuthorizationException (expected because User:$CLIENT is not allowed to create topics)"
else
  echo "FAIL: Something went wrong, check output"
fi

echo -e "\n# Grant the principal User:$CLIENT to the ResourceOwner role for Topic:$TOPIC"
echo "confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Topic:$TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Topic:$TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Try to create topic $TOPIC, after authorization (should pass)"
echo "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/client.properties.delta"
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/client.properties.delta

echo -e "\n# List topics, it should show only topic $TOPIC"
echo "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --list --command-config $DELTA_CONFIGS_DIR/client.properties.delta"
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --list --command-config $DELTA_CONFIGS_DIR/client.properties.delta

echo -e "\n# Produce to topic $TOPIC"
echo "seq 10 | confluent local produce $TOPIC -- --producer.config $DELTA_CONFIGS_DIR/client.properties.delta"
seq 10 | confluent local produce $TOPIC -- --producer.config $DELTA_CONFIGS_DIR/client.properties.delta

echo -e "\n# Consume from topic $TOPIC from RBAC endpoint (should fail)"
echo "confluent local consume test-topic-1 -- --consumer.config $DELTA_CONFIGS_DIR/client.properties.delta --from-beginning --max-messages 10"
OUTPUT=$(confluent local consume test-topic-1 -- --consumer.config $DELTA_CONFIGS_DIR/client.properties.delta --from-beginning --max-messages 10 2>&1)
if [[ $OUTPUT =~ "org.apache.kafka.common.errors.GroupAuthorizationException" ]]; then
  echo "PASS: Consume failed due to org.apache.kafka.common.errors.GroupAuthorizationException (expected because User:$CLIENT is not allowed access to consumer groups)"
else
  echo "FAIL: Something went wrong, check output"
fi

echo -e "#\n Create a role binding to the resource Group:console-consumer-"
echo "confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Group:console-consumer- --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Group:console-consumer- --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Consume from topic $TOPIC from RBAC endpoint (should pass)"
echo "confluent local consume test-topic-1 -- --consumer.config $DELTA_CONFIGS_DIR/client.properties.delta --from-beginning --max-messages 10"
confluent local consume test-topic-1 -- --consumer.config $DELTA_CONFIGS_DIR/client.properties.delta --from-beginning --max-messages 10

echo -e "\n# Consume from topic $TOPIC from PLAINTEXT endpoint"
echo "confluent local consume test-topic-1 -- --bootstrap-server localhost:9093 --from-beginning --max-messages 10"
confluent local consume test-topic-1 -- --bootstrap-server localhost:9093 --from-beginning --max-messages 10


##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=../rbac_configs
restore_configs $CONFLUENT_HOME/etc/kafka/server.properties $ORIGINAL_CONFIGS_DIR/server.properties $SAVE_CONFIGS_DIR/server.properties.rbac
