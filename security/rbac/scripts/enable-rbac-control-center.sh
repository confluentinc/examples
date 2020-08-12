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
FILENAME=control-center-dev.properties
create_temp_configs $CONFLUENT_HOME/etc/confluent-control-center/$FILENAME $ORIGINAL_CONFIGS_DIR/$FILENAME $DELTA_CONFIGS_DIR/${FILENAME}.delta

# Log in to Metadata Server (MDS)
login_mds $MDS

##################################################
# Administrative Functions
# - Grant principal User:$USER_ADMIN_C3 the SystemAdmin role to the Kafka cluster
##################################################

# Get the Kafka cluster id
get_cluster_id_kafka
echo -e "\n# Grant principal User:$USER_ADMIN_C3 the SystemAdmin role to the Kafka cluster"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_C3 --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_C3 --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Bring up Control Center"
confluent local services control-center start

echo "Sleeping 10 seconds"
sleep 10

##################################################
# Control Center client functions
# From the Control Center UI, login with username=clientc and password=clientc1
#
# For C3 topic inspection on topic with non-Avro data
# - Grant principal User:$USER_CLIENT_C the DeveloperRead role to Topic:$TOPIC1
#
# For C3 topic inspection on topic with Avro data and Schema Registry integration
# - Grant principal User:$USER_CLIENT_C the DeveloperRead role to Topic:$TOPIC2_AVRO
# - Grant principal User:$USER_CLIENT_C the DeveloperRead role to Subject:${TOPIC2_AVRO}-value
#
# For C3 connect cluster
# - Grant principal User:$USER_CLIENT_C the DeveloperRead role to Connector:$CONNECTOR_NAME
##################################################

echo -e "\n# Grant principal User:$USER_CLIENT_C the DeveloperRead role to Topic:$TOPIC1"
echo "confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID

get_cluster_id_schema_registry
echo -e "\n# Grant principal User:$USER_CLIENT_C the DeveloperRead role to Topic:$TOPIC2_AVRO"
echo "confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Topic:$TOPIC2_AVRO --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Topic:$TOPIC2_AVRO --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:$USER_CLIENT_C the DeveloperRead role to Subject:${TOPIC2_AVRO}-value"
echo "confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Subject:${TOPIC2_AVRO}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Subject:${TOPIC2_AVRO}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

get_cluster_id_connect
echo -e "\n# Grant principal User:$USER_CLIENT_C the DeveloperRead role to Connector:$CONNECTOR_NAME"
echo "confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Connector:$CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Connector:$CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID

echo -e "\n# List the role bindings for User:$USER_CLIENT_C to the Kafka cluster"
echo "confluent iam rolebinding list --principal User:$USER_CLIENT_C --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_CLIENT_C --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n # Note: From the Control Center UI, login with username=clientc and password=clientc1"

##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/confluent-control-center/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
