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
# - Grant SecurityAdmin access to the Connect cluster administrator $ADMIN_CONNECT
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

echo -e "\n# Install kafka-connect-datagen"
echo "confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:latest"
confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:latest

echo -e "\n# Bring up Connect"
confluent local start connect

echo -e "Sleeping 20 seconds before getting the Connect cluster ID"
sleep 20
get_cluster_id_connect

echo -e "\n# Grant the principal User:$ADMIN_CONNECT to the SecurityAdmin role to make requests to the MDS to learn whether the user hitting its REST API is authorized to perform certain actions"
echo "confluent iam rolebinding create --principal User:$ADMIN_CONNECT --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_CONNECT --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID

##################################################
# Connect client functions
# - Grant the principal User:$CLIENT to the ResourceOwner role for Connector:$CONNECTOR_NAME
# - Grant the principal User:$CLIENT to the ResourceOwner role for Topic:$DATA_TOPIC
# - Grant the principal User:$CLIENT to the ResourceOwner role for Subject:${DATA_TOPIC}-value"
# - List roles
# - Create the connector
# - Consume messages from the $DATA_TOPIC topic
##################################################

DATA_TOPIC=pageviews
CONNECTOR_NAME=datagen-pageviews

echo -e "\n# Grant the principal User:$CLIENT to the ResourceOwner role for Connector:$CONNECTOR_NAME"
echo "confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Connector:$CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID"
confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Connector:$CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$CLIENT for the Connect cluster"
echo "confluent iam rolebinding list --principal User:$CLIENT --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID"
confluent iam rolebinding list --principal User:$CLIENT --kafka-cluster-id $KAFKA_CLUSTER_I --connect-cluster-id $CONNECT_CLUSTER_IDD

echo -e "\n# Grant the principal User:$CLIENT to the ResourceOwner role for Topic:$DATA_TOPIC"
echo "confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Topic:$DATA_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Topic:$DATA_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$CLIENT for the Kafka cluster"
echo "confluent iam rolebinding list --principal User:$CLIENT --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$CLIENT --kafka-cluster-id $KAFKA_CLUSTER_ID

get_cluster_id_schema_registry
echo -e "\n# Grant the principal User:$CLIENT to the ResourceOwner role for Subject:${DATA_TOPIC}-value"
echo "confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Subject:${DATA_TOPIC}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Subject:${DATA_TOPIC}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$CLIENT for the Schema Registry cluster"
echo "confluent iam rolebinding list --principal User:$CLIENT --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding list --principal User:$CLIENT --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

#cp ../config/kafka-connect-datagen-connector.cfg /tmp/kafka-connect-datagen-connector.cfg
#cat ${DELTA_CONFIGS_DIR}/connector-source.properties.delta >> /tmp/kafka-connect-datagen-connector.cfg
#confluent local config kafka-connect-datagen -- -d /tmp/kafka-connect-datagen-connector.cfg
echo -e "\n# Create the connector"
./submit_datagen_pageviews_config_avro.sh 

# Consume messages from the $DATA_TOPIC topic
echo -e "\n# Consume messages from the $DATA_TOPIC topic"
cat << EOF
confluent local consume $DATA_TOPIC -- --bootstrap-server localhost:9093 --from-beginning --max-messages 10 \\
  --value-format avro \\
  --property basic.auth.credentials.source=USER_INFO \\
  --property schema.registry.basic.auth.user.info=$CLIENT:client1 \\
  --property schema.registry.url=http://localhost:8081
EOF
confluent local consume $DATA_TOPIC -- --bootstrap-server localhost:9093 --from-beginning --max-messages 10 \
  --value-format avro \
  --property basic.auth.credentials.source=USER_INFO \
  --property schema.registry.basic.auth.user.info=$CLIENT:client1 \
  --property schema.registry.url=http://localhost:8081

##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/schema-registry/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
#mv /tmp/kafka-connect-datagen-connector.cfg ${SAVE_CONFIGS_DIR}/kafka-connect-datagen-connector.cfg.rbac
