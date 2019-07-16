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
ORIGINAL_CONFIGS_DIR=/tmp/original_configs
DELTA_CONFIGS_DIR=../delta_configs
FILENAME=kafka-rest.properties
create_temp_configs $CONFLUENT_HOME/etc/kafka-rest/$FILENAME $ORIGINAL_CONFIGS_DIR/$FILENAME $DELTA_CONFIGS_DIR/${FILENAME}.delta

# Log in to Metadata Server (MDS)
login_mds $MDS

##################################################
# Administrative Functions
# - Start REST Proxy
# - No additional role bindings are required because REST Proxy just does impersonation
##################################################

# Get the Kafka cluster id
get_cluster_id_kafka

confluent local start kafka-rest

##################################################
# REST Proxy client functions
# - Grant the principal User:$CLIENTB to the ResourceOwner role for Topic:$TOPIC
# - Create topic $TOPIC
# - Produce to topic $TOPIC
# - View topics (should see one topic $TOPIC)
# - Create a consumer group $CONSUMER_GROUP
# - Subscribe to the topic $TOPIC
# - Consume messages from the topic $TOPIC, before authorization (should fail)
# - Grant the principal User:$CLIENTB to the DeveloperRead role for Group:$CONSUMER_GROUP
# - Consume messages from the topic $TOPIC, after authorization (should pass)
# - List the role bindings for User:$CLIENTB to the Kafka cluster
##################################################

TOPIC=test-topic-2

echo -e "\n# Grant principal User:$CLIENTB the ResourceOwner role to Topic:$TOPIC"
echo "confluent iam rolebinding create --principal User:$CLIENTB --role ResourceOwner --resource Topic:$TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$CLIENTB --role ResourceOwner --resource Topic:$TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Create topic $TOPIC"
echo "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/clientb.properties.delta"
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/clientb.properties.delta

echo -e "\n# Produce to topic $TOPIC"
for i in {1..3}; do
  echo 'curl -u clientb:clientb1 -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" -H "Accept: application/vnd.kafka.v2+json" --data '"'"'{"records":[{"value":"message'"${i}"'"}]}'"'"' http://localhost:8082/topics/'"$TOPIC"
  curl -u clientb:clientb1 -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" -H "Accept: application/vnd.kafka.v2+json" --data '{"records":[{"value":"message'"${i}"'"}]}' "http://localhost:8082/topics/$TOPIC"
  echo
done

echo -e "\n# View topics (should see one topic $TOPIC)"
echo "curl -u clientb:clientb1 http://localhost:8082/topics"
curl -u clientb:clientb1 http://localhost:8082/topics
echo

CONSUMER_GROUP=rest_proxy_consumer_group

echo -e "\n# Create a consumer group $CONSUMER_GROUP"
echo 'curl -u clientb:clientb1 -X POST -H "Content-Type: application/vnd.kafka.v2+json" -H "Accept: application/vnd.kafka.v2+json" --data '"'"'{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}'"'"' http://localhost:8082/consumers/'"$CONSUMER_GROUP"
curl -u clientb:clientb1 -X POST -H "Content-Type: application/vnd.kafka.v2+json" -H "Accept: application/vnd.kafka.v2+json" --data '{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}' http://localhost:8082/consumers/$CONSUMER_GROUP
echo

echo -e "\n# Subscribe to the topic $TOPIC"
echo 'curl -u clientb:clientb1 --silent -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '"'"'{"topics":["'"$TOPIC"'"]}'"'"' http://localhost:8082/consumers/'"$CONSUMER_GROUP"'/instances/my_consumer_instance/subscription'
curl -u clientb:clientb1 --silent -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '{"topics":["'"$TOPIC"'"]}' http://localhost:8082/consumers/$CONSUMER_GROUP/instances/my_consumer_instance/subscription

echo -e "\n# Consume messages from the topic $TOPIC, before authorization (should fail)"
OUTPUT=$(curl -u $CLIENTB:clientb1 --silent -X GET -H "Accept: application/vnd.kafka.json.v2+json" http://localhost:8082/consumers/$CONSUMER_GROUP/instances/my_consumer_instance/records)
echo $OUTPUT
if [[ $OUTPUT =~ "Not authorized to access group" ]]; then
  echo "PASS: Consuming messages from topic $TOPIC failed due to Not authorized to access group (expected because User:$CLIENTB is not allowed access to the consumer group)"
else
  echo "FAIL: Something went wrong, check output"
fi

echo -e "\n# Grant the principal User:$CLIENTB to the DeveloperRead role for Group:$CONSUMER_GROUP"
echo "confluent iam rolebinding create --principal User:$CLIENTB --role DeveloperRead --resource Group:$CONSUMER_GROUP --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$CLIENTB --role DeveloperRead --resource Group:$CONSUMER_GROUP --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Consume messages from the topic $TOPIC, after authorization (should pass)"
echo 'curl -u clientb:clientb1 --silent -X GET -H "Accept: application/vnd.kafka.json.v2+json" http://localhost:8082/consumers/'"$CONSUMER_GROUP"'/instances/my_consumer_instance/records'
curl -u $CLIENTB:clientb1 --silent -X GET -H "Accept: application/vnd.kafka.json.v2+json" http://localhost:8082/consumers/$CONSUMER_GROUP/instances/my_consumer_instance/records
echo

echo -e "\n# List the role bindings for User:$CLIENTB to the Kafka cluster"
echo "confluent iam rolebinding list --principal User:$CLIENTB --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$CLIENTB --kafka-cluster-id $KAFKA_CLUSTER_ID

##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/kafka-rest/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
