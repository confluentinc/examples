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
FILENAME=ksql-server.properties
create_temp_configs $CONFLUENT_HOME/etc/ksql/$FILENAME $ORIGINAL_CONFIGS_DIR/$FILENAME $DELTA_CONFIGS_DIR/${FILENAME}.delta

# Log in to Metadata Server (MDS)
login_mds $MDS

##################################################
# Administrative Functions
# - Grant principal User:$ADMIN_KSQL the ResourceOwner role to Topic:_confluent-ksql-${KSQL_SERVICE_ID}_command_topic
# - Grant principal User:$ADMIN_KSQL the ResourceOwner role to Topic:${KSQL_SERVICE_ID}ksql_processing_log
# - Grant principal User:$ADMIN_KSQL the ResourceOwner role to Group:_confluent-ksql-${KSQL_SERVICE_ID} prefix
# - Start KSQL
# - Grant principal User:$ADMIN_KSQL the SecurityAdmin role to the KSQL Cluster
# - Grant principal User:$ADMIN_KSQL the ResourceOwner role to KsqlCluster:ksql-cluster
##################################################

# Get the Kafka cluster id
get_cluster_id_kafka

# How to get this before starting?
KSQL_CLUSTER_ID=ksql-server

# Use the default KSQL app identifier
KSQL_SERVICE_ID=default_

echo -e "\n# Grant principal User:$ADMIN_KSQL the ResourceOwner role to Topic:_confluent-ksql-${KSQL_SERVICE_ID}_command_topic"
echo "confluent iam rolebinding create --principal User:$ADMIN_KSQL --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}_command_topic --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_KSQL --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}_command_topic --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:$ADMIN_KSQL the ResourceOwner role to Topic:${KSQL_SERVICE_ID}ksql_processing_log"
echo "confluent iam rolebinding create --principal User:$ADMIN_KSQL --role ResourceOwner --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_KSQL --role ResourceOwner --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:$ADMIN_KSQL the ResourceOwner role to Group:_confluent-ksql-${KSQL_SERVICE_ID} prefix"
echo "confluent iam rolebinding create --principal User:$ADMIN_KSQL --role ResourceOwner --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_KSQL --role ResourceOwner --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Bring up KSQL server"
confluent local start ksql-server

echo -e "\n# Grant principal User:$ADMIN_KSQL the SecurityAdmin role to th KSQL Cluster to make requests to the MDS to learn whether the user hitting its REST API is authorized to perform certain actions"
echo "confluent iam rolebinding create --principal User:$ADMIN_KSQL --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_KSQL --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_CLUSTER_ID

echo -e "\n# Grant principal User:$ADMIN_KSQL the ResourceOwner role to KsqlCluster:ksql-cluster"
echo "confluent iam rolebinding create --principal User:$ADMIN_KSQL --role ResourceOwner --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_KSQL --role ResourceOwner --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$ADMIN_KSQL"
echo "confluent iam rolebinding list --principal User:$ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$ADMIN_KSQL to the KSQL cluster"
echo "confluent iam rolebinding list --principal User:$ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_CLUSTER_ID"
confluent iam rolebinding list --principal User:$ADMIN_KSQL --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_CLUSTER_ID


##################################################
# KSQL client functions
##################################################


##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/ksql/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
