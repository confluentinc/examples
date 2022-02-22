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
FILENAME=kafka-rest.properties
create_temp_configs $CONFLUENT_HOME/etc/kafka-rest/$FILENAME $ORIGINAL_CONFIGS_DIR/$FILENAME $DELTA_CONFIGS_DIR/${FILENAME}.delta

# Log in to Metadata Server (MDS)
login_mds $MDS

##################################################
# Administrative Functions
# - Grant principal User:$USER_CLIENT_RP the DeveloperRead role to Topic:$LICENSE_TOPIC
# - Grant principal User:$USER_CLIENT_RP the DeveloperWrite role to Topic:$LICENSE_TOPIC
# - Start REST Proxy
# - No additional role bindings are required because REST Proxy just does impersonation
##################################################

# Get the Kafka cluster id
get_cluster_id_kafka

echo -e "\n# Grant principal User:$USER_CLIENT_RP the DeveloperRead and DeveloperWrite roles to Topic:$LICENSE_TOPIC"
echo "confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role DeveloperRead --resource Topic:$LICENSE_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID"
echo "confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role DeveloperWrite --resource Topic:$LICENSE_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role DeveloperRead --resource Topic:$LICENSE_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role DeveloperWrite --resource Topic:$LICENSE_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent local services kafka-rest start

##################################################
# REST Proxy client functions
# - Grant the principal User:$USER_CLIENT_RP to the ResourceOwner role for Topic:$TOPIC3
# - Create topic $TOPIC3
# - Produce to topic $TOPIC3
# - View topics (should see one topic $TOPIC3)
# - Create a consumer group $CONSUMER_GROUP
# - Subscribe to the topic $TOPIC3
# - Consume messages from the topic $TOPIC3, before authorization (should fail)
# - Grant the principal User:$USER_CLIENT_RP to the DeveloperRead role for Group:$CONSUMER_GROUP
# - Consume messages from the topic $TOPIC3, after authorization (should pass)
# - List the role bindings for User:$USER_CLIENT_RP to the Kafka cluster
##################################################

echo -e "\n# Grant principal User:$USER_CLIENT_RP the ResourceOwner role to Topic:$TOPIC3"
echo "confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role ResourceOwner --resource Topic:$TOPIC3 --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role ResourceOwner --resource Topic:$TOPIC3 --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Create topic $TOPIC3"
echo "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC3 --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/clientrp.properties.delta"
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC3 --replication-factor 1 --partitions 3 --command-config $DELTA_CONFIGS_DIR/clientrp.properties.delta

echo -e "\n# Produce to topic $TOPIC3"
for i in {1..3}; do
  echo 'curl -u '"${USER_CLIENT_RP}:${USER_CLIENT_RP}1"' -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" -H "Accept: application/vnd.kafka.v2+json" --data '"'"'{"records":[{"value":"message'"${i}"'"}]}'"'"' http://localhost:8082/topics/'"$TOPIC3"
  curl -u ${USER_CLIENT_RP}:${USER_CLIENT_RP}1 -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" -H "Accept: application/vnd.kafka.v2+json" --data '{"records":[{"value":"message'"${i}"'"}]}' "http://localhost:8082/topics/$TOPIC3"
  echo
done

echo -e "\n# View topics (should see one topic $TOPIC3)"
echo "curl -u ${USER_CLIENT_RP}:${USER_CLIENT_RP}1 http://localhost:8082/topics"
curl -u ${USER_CLIENT_RP}:${USER_CLIENT_RP}1 http://localhost:8082/topics
echo

CONSUMER_GROUP=rest_proxy_consumer_group

echo -e "\n# Create a consumer group $CONSUMER_GROUP"
echo 'curl -u '"${USER_CLIENT_RP}:${USER_CLIENT_RP}1"' -X POST -H "Content-Type: application/vnd.kafka.v2+json" -H "Accept: application/vnd.kafka.v2+json" --data '"'"'{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}'"'"' http://localhost:8082/consumers/'"$CONSUMER_GROUP"
curl -u ${USER_CLIENT_RP}:${USER_CLIENT_RP}1 -X POST -H "Content-Type: application/vnd.kafka.v2+json" -H "Accept: application/vnd.kafka.v2+json" --data '{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}' http://localhost:8082/consumers/$CONSUMER_GROUP
echo

echo -e "\n# Subscribe to the topic $TOPIC3"
echo 'curl -u '"${USER_CLIENT_RP}:${USER_CLIENT_RP}1"' --silent -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '"'"'{"topics":["'"$TOPIC3"'"]}'"'"' http://localhost:8082/consumers/'"$CONSUMER_GROUP"'/instances/my_consumer_instance/subscription'
curl -u ${USER_CLIENT_RP}:${USER_CLIENT_RP}1 --silent -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '{"topics":["'"$TOPIC3"'"]}' http://localhost:8082/consumers/$CONSUMER_GROUP/instances/my_consumer_instance/subscription

echo -e "\n# Consume messages from the topic $TOPIC3, before authorization (should fail)"
OUTPUT=$(curl -u $USER_CLIENT_RP:${USER_CLIENT_RP}1 --silent -X GET -H "Accept: application/vnd.kafka.json.v2+json" http://localhost:8082/consumers/$CONSUMER_GROUP/instances/my_consumer_instance/records)
echo $OUTPUT
if [[ $OUTPUT =~ "Not authorized to access group" ]]; then
  echo "PASS: Consuming messages from topic $TOPIC3 failed due to Not authorized to access group (expected because User:$USER_CLIENT_RP is not allowed access to the consumer group)"
else
  echo -e "FAIL: Something went wrong, check output:\n$OUTPUT"
fi

echo -e "\n# Grant the principal User:$USER_CLIENT_RP to the DeveloperRead role for Group:$CONSUMER_GROUP"
echo "confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role DeveloperRead --resource Group:$CONSUMER_GROUP --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role DeveloperRead --resource Group:$CONSUMER_GROUP --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Consume messages from the topic $TOPIC3, after authorization (should pass)"
echo 'curl -u '"${USER_CLIENT_RP}:${USER_CLIENT_RP}1"' --silent -X GET -H "Accept: application/vnd.kafka.json.v2+json" http://localhost:8082/consumers/'"$CONSUMER_GROUP"'/instances/my_consumer_instance/records'
# Execute twice due to https://github.com/confluentinc/kafka-rest/issues/432
curl -u $USER_CLIENT_RP:${USER_CLIENT_RP}1 --silent -X GET -H "Accept: application/vnd.kafka.json.v2+json" http://localhost:8082/consumers/$CONSUMER_GROUP/instances/my_consumer_instance/records
curl -u $USER_CLIENT_RP:${USER_CLIENT_RP}1 --silent -X GET -H "Accept: application/vnd.kafka.json.v2+json" http://localhost:8082/consumers/$CONSUMER_GROUP/instances/my_consumer_instance/records
echo

echo -e "\n# List the role bindings for User:$USER_CLIENT_RP to the Kafka cluster"
echo "confluent iam rolebinding list --principal User:$USER_CLIENT_RP --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_CLIENT_RP --kafka-cluster-id $KAFKA_CLUSTER_ID

##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/kafka-rest/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
