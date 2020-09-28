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
FILENAME=schema-registry.properties
create_temp_configs $CONFLUENT_HOME/etc/schema-registry/$FILENAME $ORIGINAL_CONFIGS_DIR/$FILENAME $DELTA_CONFIGS_DIR/${FILENAME}.delta

# Log in to Metadata Server (MDS)
login_mds $MDS

##################################################
# Administrative Functions
# - Grant principal User:$USER_ADMIN_SCHEMA_REGISTRY the ResourceOwner role to Topic:_schemas
# - Grant principal User:$USER_ADMIN_SCHEMA_REGISTRY the ResourceOwner role to Group:schema-registry-demo
# - Grant principal User:$USER_ADMIN_SCHEMA_REGISTRY the DeveloperRead role to Topic:$LICENSE_TOPIC
# - Grant principal User:$USER_ADMIN_SCHEMA_REGISTRY the DeveloperWrite role to Topic:$LICENSE_TOPIC
# - Start Schema Registry
# - Grant principal User:$USER_ADMIN_SCHEMA_REGISTRY the SecurityAdmin role to the Schema Registry cluster
# - List the role bindings for User:$USER_ADMIN_SCHEMA_REGISTRY
##################################################

# Get the Kafka cluster id
get_cluster_id_kafka

echo -e "\n# Grant principal User:$USER_ADMIN_SCHEMA_REGISTRY the ResourceOwner role to Topic:_schemas"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Topic:_schemas --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Topic:_schemas --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:$USER_ADMIN_SCHEMA_REGISTRY the ResourceOwner role to Group:schema-registry-demo"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Group:schema-registry-demo --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Group:schema-registry-demo --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Grant principal User:$USER_ADMIN_SCHEMA_REGISTRY the DeveloperRead and DeveloperWrite roles to Topic:$LICENSE_TOPIC"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role DeveloperRead --resource Topic:$LICENSE_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role DeveloperWrite --resource Topic:$LICENSE_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role DeveloperRead --resource Topic:$LICENSE_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role DeveloperWrite --resource Topic:$LICENSE_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Bring up Schema Registry"
confluent local services schema-registry start

echo -e "Sleeping 10 seconds before getting the Schema Registry cluster ID"
sleep 10

get_cluster_id_schema_registry

echo -e "\n# Grant principal User:$USER_ADMIN_SCHEMA_REGISTRY the SecurityAdmin role to the Schema Registry cluster to make requests to the MDS to learn whether the user hitting its REST API is authorized to perform certain actions"
echo "confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

echo -e "\n# List the role bindings for User:$USER_ADMIN_SCHEMA_REGISTRY to the Kafka cluster"
echo "confluent iam rolebinding list --principal User:$USER_ADMIN_SCHEMA_REGISTRY --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_ADMIN_SCHEMA_REGISTRY --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for User:$USER_ADMIN_SCHEMA_REGISTRY to the Schema Registry cluster"
echo "confluent iam rolebinding list --principal User:$USER_ADMIN_SCHEMA_REGISTRY --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_ADMIN_SCHEMA_REGISTRY --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID


##################################################
# Schema Registry client functions
# - Grant principal User:$USER_CLIENT_A the ResourceOwner role to Subject:$SUBJECT
# - List the role bindings for User:$USER_CLIENT_A
# - Register new schema for subject $SUBJECT
# - View schema
##################################################

SUBJECT="new-topic-value"
echo -e "\n# Register new schema for subject $SUBJECT (should fail)"
echo "curl --silent -u $USER_CLIENT_A:${USER_CLIENT_A}1 -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '"'{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"},{\"name\":\"region\",\"type\":\"string\"}]}"}'"' http://localhost:8081/subjects/$SUBJECT/versions"
OUTPUT=$(curl --silent -u $USER_CLIENT_A:${USER_CLIENT_A}1 -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"},{\"name\":\"region\",\"type\":\"string\"}]}"}' http://localhost:8081/subjects/$SUBJECT/versions)
if [[ $OUTPUT =~ "User is denied operation" ]]; then
  echo "PASS: Schema registration failed due to 'User is denied operation'"
else
  echo -e "FAIL: Something went wrong, check output:\n$OUTPUT"
fi

echo -e "\n# Grant principal User:$USER_CLIENT_A the ResourceOwner role to Subject:$SUBJECT"
echo "confluent iam rolebinding create --principal User:$USER_CLIENT_A --role ResourceOwner --resource Subject:$SUBJECT --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding create --principal User:$USER_CLIENT_A --role ResourceOwner --resource Subject:$SUBJECT --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

echo -e "\n# List the role bindings for User:$USER_CLIENT_A"
echo "confluent iam rolebinding list --principal User:$USER_CLIENT_A --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding list --principal User:$USER_CLIENT_A --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

echo -e "\n# Register new schema for subject $SUBJECT (should pass)"
echo "curl --silent -u $USER_CLIENT_A:${USER_CLIENT_A}1 -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '"'{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"},{\"name\":\"region\",\"type\":\"string\"}]}"}'"' http://localhost:8081/subjects/$SUBJECT/versions"
curl --silent -u $USER_CLIENT_A:${USER_CLIENT_A}1 -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"},{\"name\":\"region\",\"type\":\"string\"}]}"}' http://localhost:8081/subjects/$SUBJECT/versions

echo -e "\n\n# View new schema"
echo "curl --silent -u $USER_CLIENT_A:${USER_CLIENT_A}1 http://localhost:8081/subjects/$SUBJECT/versions/latest | jq ."
curl --silent -u $USER_CLIENT_A:${USER_CLIENT_A}1 http://localhost:8081/subjects/$SUBJECT/versions/latest | jq .


##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=/tmp/rbac_configs
restore_configs $CONFLUENT_HOME/etc/schema-registry/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
