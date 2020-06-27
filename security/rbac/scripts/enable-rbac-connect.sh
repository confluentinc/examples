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
FILENAME=connect-avro-distributed.properties
create_temp_configs $CONFLUENT_HOME/etc/schema-registry/$FILENAME $ORIGINAL_CONFIGS_DIR/$FILENAME $DELTA_CONFIGS_DIR/${FILENAME}.delta

# Log in to Metadata Server (MDS)
login_mds $MDS

##################################################
# Administrative Functions
# - Grant principal User:$USER_ADMIN_CONNECT the ResourceOwner role to Topic:connect-configs
# - Grant principal User:$USER_ADMIN_CONNECT the ResourceOwner role to Topic:connect-offsets
# - Grant principal User:$USER_ADMIN_CONNECT the ResourceOwner role to Topic:connect-statuses
# - Grant principal User:$USER_ADMIN_CONNECT the ResourceOwner role to Group:connect-cluster
# - Grant principal User:$USER_ADMIN_CONNECT the ResourceOwner role to Topic:_confluent-secrets (for Secret Registry)
# - Grant principal User:$USER_ADMIN_CONNECT the ResourceOwner role to Group:secret-registry (for Secret Registry)
# - Start connect
# - Grant principal User:$USER_ADMIN_CONNECT the SecurityAdmin role to the Connect cluster
# - List role bindings
##################################################

# Get the Kafka cluster id
get_cluster_id_kafka

echo -e "\n# Grant principal User:$USER_ADMIN_CONNECT the ResourceOwner role to Topic:connect-configs"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-configs --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-configs --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:$USER_ADMIN_CONNECT the ResourceOwner role to Topic:connect-offsets"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-offsets --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-offsets --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:$USER_ADMIN_CONNECT the ResourceOwner role to Topic:connect-statuses"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-statuses --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-statuses --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:$USER_ADMIN_CONNECT to the ResourceOwner role to Group:connect-cluster"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Group:connect-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Group:connect-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:$USER_ADMIN_CONNECT the ResourceOwner role to Topic:_confluent-secrets (for Secret Registry)"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:_confluent-secrets --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:_confluent-secrets --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:$USER_ADMIN_CONNECT the ResourceOwner role to Group:secret-registry (for Secret Registry)"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Group:secret-registry --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Group:secret-registry --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for User:$USER_ADMIN_CONNECT to the Kafka cluster"
echo "confluent iam rolebinding list --principal User:$USER_ADMIN_CONNECT --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_ADMIN_CONNECT --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Install kafka-connect-datagen"
echo "confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:$KAFKA_CONNECT_DATAGEN_VERSION"
confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:$KAFKA_CONNECT_DATAGEN_VERSION

echo -e "\n# Bring up Connect"
confluent local services connect start

echo -e "Sleeping 30 seconds before getting the Connect cluster ID"
sleep 30
get_cluster_id_connect

echo -e "\n# Grant principal User:$USER_ADMIN_CONNECT the SecurityAdmin role to make requests to the MDS to learn whether the user hitting its REST API is authorized to perform certain actions"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$USER_ADMIN_CONNECT to the Connect cluster"
echo "confluent iam rolebinding list --principal User:$USER_ADMIN_CONNECT --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_ADMIN_CONNECT --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID

##################################################
# Connect client functions
# - Grant principal User:$USER_CONNECTOR_SUBMITTER the ResourceOwner role to Connector:$CONNECTOR_NAME
# - Grant principal User:$USER_CONNECTOR the ResourceOwner role to Topic:$TOPIC2_AVRO
# - Grant principal User:$USER_CONNECTOR the ResourceOwner role to Subject:${TOPIC2_AVRO}-value"
# - List roles
# - Create the connector
# - Grant principal User:$USER_CONNECTOR the DeveloperRead role to Group:console-consumer- prefix
# - Consume messages from the $TOPIC2_AVRO topic
##################################################

CONNECTOR_NAME=datagen-pageviews

echo -e "\n# Grant principal User:$USER_CONNECTOR_SUBMITTER the ResourceOwner role to Connector:$CONNECTOR_NAME"
echo "confluent iam rolebinding create --principal User:$USER_CONNECTOR_SUBMITTER --role ResourceOwner --resource Connector:$CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CONNECTOR_SUBMITTER --role ResourceOwner --resource Connector:$CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$USER_CONNECTOR_SUBMITTER to the Connect cluster"
echo "confluent iam rolebinding list --principal User:$USER_CONNECTOR_SUBMITTER --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_CONNECTOR_SUBMITTER --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID

echo -e "\n# Grant principal User:$USER_CONNECTOR the ResourceOwner role to Topic:$TOPIC2_AVRO"
echo "confluent iam rolebinding create --principal User:$USER_CONNECTOR --role ResourceOwner --resource Topic:$TOPIC2_AVRO --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CONNECTOR --role ResourceOwner --resource Topic:$TOPIC2_AVRO --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$USER_CONNECTOR to the Kafka cluster"
echo "confluent iam rolebinding list --principal User:$USER_CONNECTOR --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_CONNECTOR --kafka-cluster-id $KAFKA_CLUSTER_ID

get_cluster_id_schema_registry
echo -e "\n# Grant principal User:$USER_CONNECTOR the ResourceOwner role to Subject:${TOPIC2_AVRO}-value"
echo "confluent iam rolebinding create --principal User:$USER_CONNECTOR --role ResourceOwner --resource Subject:${TOPIC2_AVRO}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CONNECTOR --role ResourceOwner --resource Subject:${TOPIC2_AVRO}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

echo -e "\n# List the role bindings for the principal User:$USER_CONNECTOR to the Schema Registry cluster"
echo "confluent iam rolebinding list --principal User:$USER_CONNECTOR --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_CONNECTOR --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

echo -e "\n# Create the connector"
./submit_datagen_pageviews_config_avro.sh 

# Consume messages from the $TOPIC2_AVRO topic
echo -e "#\n Grant principal User:$USER_CONNECTOR the DeveloperRead role to Group:console-consumer- prefix"
echo "confluent iam rolebinding create --principal User:$USER_CONNECTOR --role DeveloperRead --resource Group:console-consumer- --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CONNECTOR --role DeveloperRead --resource Group:console-consumer- --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Consume from topic $TOPIC2_AVRO from PLAINTEXT endpoint"
cat << EOF
confluent local services kafka consume $TOPIC2_AVRO --bootstrap-server $BOOTSTRAP_SERVER_PLAINTEXT --from-beginning --max-messages 10 \\
  --value-format avro \\
  --property basic.auth.credentials.source=USER_INFO \\
  --property schema.registry.basic.auth.user.info=$USER_CONNECTOR:${USER_CONNECTOR}1 \
  --property schema.registry.url=http://localhost:8081
EOF
confluent local services kafka consume $TOPIC2_AVRO --bootstrap-server $BOOTSTRAP_SERVER_PLAINTEXT --from-beginning --max-messages 10 \
  --value-format avro \
  --property basic.auth.credentials.source=USER_INFO \
  --property schema.registry.basic.auth.user.info=$USER_CONNECTOR:${USER_CONNECTOR}1 \
  --property schema.registry.url=http://localhost:8081

##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/schema-registry/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
