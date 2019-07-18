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

. ../config/local-demo.env
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
confluent local start control-center

echo "Sleeping 10 seconds"
sleep 10

##################################################
# Control Center client functions
# From the Control Center UI, login with username=clientc and password=clientc1
##################################################

confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID

get_cluster_id_schema_registry
confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Topic:$TOPIC2_AVRO --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Subject:${TOPIC2_AVRO}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

get_cluster_id_connect
confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Connector:$CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID

echo -e "\n# List the role bindings for User:$USER_CLIENT_C to the Kafka cluster"
echo "confluent iam rolebinding list --principal User:$USER_CLIENT_C --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_CLIENT_C --kafka-cluster-id $KAFKA_CLUSTER_ID


curl --silent -u $USER_CLIENT_C:${USER_CLIENT_C}1 http://localhost:8081/subjects/${TOPIC2_AVRO}-value/versions/latest | jq .


##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/confluent-control-center/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
