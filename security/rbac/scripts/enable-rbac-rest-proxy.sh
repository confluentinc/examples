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
# - Aside from starting REST Proxy, no additional role bindings are required because REST Proxy just does impersonation
##################################################

# Get the Kafka cluster id
get_cluster_id_kafka

confluent local start kafka-rest

##################################################
# REST Proxy client functions
##################################################

echo -e "\n# View topics"
echo "curl -u client:client1 http://localhost:8082/topics"
curl -u client:client1 http://localhost:8082/topics

TOPIC=test-topic-1
CONSUMER_GROUP=rest_proxy_consumer_group

echo -e "\n# Create a role binding to the resource Group:$CONSUMER_GROUP"
echo "confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Group:$CONSUMER_GROUP --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Group:$CONSUMER_GROUP --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Create a consumer group $CONSUMER_GROUP"
echo 'curl -u client:client1 -X POST -H "Content-Type: application/vnd.kafka.v2+json" -H "Accept: application/vnd.kafka.v2+json" --data '{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}' http://localhost:8082/consumers/'"$CONSUMER_GROUP"
curl -u client:client1 -X POST -H "Content-Type: application/vnd.kafka.v2+json" -H "Accept: application/vnd.kafka.v2+json" --data '{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}' http://localhost:8082/consumers/$CONSUMER_GROUP

echo -e "\n# Subscribe to the topic $TOPIC"
curl -u client:client1 -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '{"topics":["test-topic-1"]}' http://localhost:8082/consumers/$CONSUMER_GROUP/instances/my_consumer_instance/subscription

echo -e "\n# Consume messages from the topic $TOPIC"
curl -u client:client1 -X GET -H "Accept: application/vnd.kafka.json.v2+json" http://localhost:8082/consumers/$CONSUMER_GROUP/instances/my_consumer_instance/records

#curl -u client:client1 -X DELETE -H "Accept: application/vnd.kafka.v2+json" http://localhost:8082/consumers/$CONSUMER_GROUP/instances/my_consumer_instance

##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/kafka-rest/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
