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
FILENAME=connect-avro-distributed.properties
create_temp_configs $CONFLUENT_HOME/etc/schema-registry/$FILENAME $ORIGINAL_CONFIGS_DIR/$FILENAME $DELTA_CONFIGS_DIR/${FILENAME}.delta

# Log in to Metadata Server (MDS)
login_mds $MDS

##################################################
# Administrative Functions
# - Grant the principal User:$ADMIN_CONNECT to the ResourceOwner role for Topic:connect-configs
# - Grant the principal User:$ADMIN_CONNECT to the ResourceOwner role for Topic:connect-offsets
# - Grant the principal User:$ADMIN_CONNECT to the ResourceOwner role for Topic:connect-statuses
# - Grant the principal User:$ADMIN_CONNECT to the ResourceOwner role for Group:connect-cluster
# - Grant the principal User:$ADMIN_CONNECT to the ResourceOwner role for Topic:_secrets (for Secret Registry)
# - Grant the principal User:$ADMIN_CONNECT to the ResourceOwner role for Group:secret-registry (for Secret Registry)
##################################################

# Get the Kafka cluster id
get_cluster_id_kafka

for CONNECT_TOPIC in connect-configs connect-offsets connect-statuses; do
  echo -e "\n# Grant the principal User:$ADMIN_CONNECT to the ResourceOwner role for Topic:${CONNECT_TOPIC}"
  echo "confluent iam rolebinding create --principal User:$ADMIN_CONNECT --role ResourceOwner --resource Topic:${CONNECT_TOPIC} --kafka-cluster-id $KAFKA_CLUSTER_ID"
  confluent iam rolebinding create --principal User:$ADMIN_CONNECT --role ResourceOwner --resource Topic:${CONNECT_TOPIC} --kafka-cluster-id $KAFKA_CLUSTER_ID
done

echo -e "\n# Grant the principal User:$ADMIN_CONNECT to the ResourceOwner role for Group:connect-cluster"
echo "confluent iam rolebinding create --principal User:$ADMIN_CONNECT --role ResourceOwner --resource Group:connect-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_CONNECT --role ResourceOwner --resource Group:connect-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant the principal User:$ADMIN_CONNECT to the ResourceOwner role for Topic:_secrets (for Secret Registry)"
echo "confluent iam rolebinding create --principal User:$ADMIN_CONNECT --role ResourceOwner --resource Topic:_secrets --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_CONNECT --role ResourceOwner --resource Topic:_secrets --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant the principal User:$ADMIN_CONNECT to the ResourceOwner role for Group:secret-registry (for Secret Registry)"
echo "confluent iam rolebinding create --principal User:$ADMIN_CONNECT --role ResourceOwner --resource Group:secret-registry --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_CONNECT --role ResourceOwner --resource Group:secret-registry --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for User:$ADMIN_CONNECT for the Kafka cluster"
echo "confluent iam rolebinding list --principal User:$ADMIN_CONNECT --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$ADMIN_CONNECT --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Bring up Connect"
confluent local start connect


##################################################
# Connect client functions
##################################################

cp ../config/kafka-connect-datagen-connector.cfg /tmp/kafka-connect-datagen-connector.cfg
cat ${DELTA_CONFIGS_DIR}/connector-source.properties.delta >> /tmp/kafka-connect-datagen-connector.cfg
confluent local config kafka-connect-datagen -- -d /tmp/kafka-connect-datagen-connector.cfg


##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/schema-registry/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
mv /tmp/kafka-connect-datagen-connector.cfg ${SAVE_CONFIGS_DIR}/kafka-connect-datagen-connector.cfg.rbac
