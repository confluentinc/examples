#!/bin/bash


################################################################################
# Overview
################################################################################
#
################################################################################

# Source library
. ../../../utils/helper.sh
. ./rbac_lib.sh

export PATH="/Users/yeva/code/bin:$PATH"
check_env || exit 1
check_cli_v2 || exit 1
check_jq || exit 1

##################################################
# Initialize
##################################################

. ../config/local-demo.cfg
ORIGINAL_CONFIGS_DIR=../original_configs
DELTA_CONFIGS_DIR=../delta_configs
create_temp_configs $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties $ORIGINAL_CONFIGS_DIR/schema-registry.properties $DELTA_CONFIGS_DIR/schema-registry.properties.delta

##################################################
# Log in to Metadata Server (MDS)
##################################################

echo -e "\n# Login"
OUTPUT=$(
expect <<END
  log_user 1
  spawn confluent login --url $MDS
  expect "Username: "
  send "$USERNAME\r";
  expect "Password: "
  send "$PASSWORD\r";
  expect "Logged in as "
  set result $expect_out(buffer)
END
)
echo "$OUTPUT"
if [[ ! "$OUTPUT" =~ "Logged in as" ]]; then
  echo "Failed to log into your Metadata Server.  Please check all parameters and run again"
  exit 1
fi

##################################################
# Schema Registry
# - Bind the principal User:$ADMIN_SCHEMA_REGISTRY to the ResourceOwner role for Topic:_schemas
# - Bring up Schema Registry
# - Grant SystemAdmin access to the Schema Registry cluster administrator $ADMIN_SCHEMA_REGISTRY
# - Grant SecurityAdmin access to the Schema Registry cluster administrator $ADMIN_SCHEMA_REGISTRY
# - Bind the principal User:$ADMIN_SCHEMA_REGISTRY to Resource Group:$SCHEMA_REGISTRY_CLUSTER_ID
# - List the role bindings for User:$ADMIN_SCHEMA_REGISTRY
# - Bind the principal User:$CLIENT to the ResourceOwner role for Subject:$SUBJECT
# - List the role bindings for User:$CLIENT
# - Register new schema for subject $SUBJECT
# - View schema
##################################################

# Get the Kafka cluster id
get_cluster_id_kafka

echo -e "\n# Bind the principal User:$ADMIN_SCHEMA_REGISTRY to the ResourceOwner role for Topic:_schemas"
echo "confluent iam rolebinding create --principal User:$ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Topic:_schemas --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Topic:_schemas --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Bring up Schema Registry"
confluent local start schema-registry

# Grant SystemAdmin and SecurityAdmin access to the Schema Registry cluster administrator `$ADMIN_SCHEMA_REGISTRY`
get_cluster_id_schema_registry
echo -e "\n# Bind the principal User:$ADMIN_SCHEMA_REGISTRY to the SystemAdmin role access to the Schema Registry cluster"
echo "confluent iam rolebinding create --principal User:$ADMIN_SCHEMA_REGISTRY --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_SCHEMA_REGISTRY --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

echo -e "\n# Bind the principal User:$ADMIN_SCHEMA_REGISTRY to the SecurityAdmin role to make requests to the MDS to learn whether the user hitting its REST API is authorized to perform certain actions"
echo "confluent iam rolebinding create --principal User:$ADMIN_SCHEMA_REGISTRY --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_SCHEMA_REGISTRY --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

echo -e "\n# Bind the principal User:$ADMIN_SCHEMA_REGISTRY to Resource Group:$SCHEMA_REGISTRY_CLUSTER_ID"
echo "confluent iam rolebinding create --principal User:$ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Group:$SCHEMA_REGISTRY_CLUSTER_ID --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Group:$SCHEMA_REGISTRY_CLUSTER_ID --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for User:$ADMIN_SCHEMA_REGISTRY for the Kafka cluster"
echo "confluent iam rolebinding list --principal User:$ADMIN_SCHEMA_REGISTRY --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$ADMIN_SCHEMA_REGISTRY --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for User:$ADMIN_SCHEMA_REGISTRY for the Schema Registry cluster"
echo "confluent iam rolebinding list --principal User:$ADMIN_SCHEMA_REGISTRY --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding list --principal User:$ADMIN_SCHEMA_REGISTRY --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

SUBJECT="new-topic-value"
echo -e "\n# Register new schema for subject $SUBJECT (should fail)"
echo "curl --silent -u $CLIENT:client1 -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '"'{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"},{\"name\":\"region\",\"type\":\"string\"}]}"}'"' http://localhost:8081/subjects/$SUBJECT/versions"
OUTPUT=$(curl --silent -u $CLIENT:client1 -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"},{\"name\":\"region\",\"type\":\"string\"}]}"}' http://localhost:8081/subjects/$SUBJECT/versions)
if [[ $OUTPUT =~ "User cannot access the resource" ]]; then
  echo "PASS: Schema registration failed due to 'User cannot access the resource'"
else
  echo "FAIL: Something went wrong, check output"
fi

echo -e "\n# Bind the principal User:$CLIENT to the ResourceOwner role for Subject:$SUBJECT"
echo "confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Subject:$SUBJECT --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Subject:$SUBJECT --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

echo -e "\n# List the role bindings for User:$CLIENT"
echo "confluent iam rolebinding list --principal User:$CLIENT --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID"
confluent iam rolebinding list --principal User:$CLIENT --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

echo -e "\n# Register new schema for subject $SUBJECT (should pass)"
echo "curl --silent -u $CLIENT:client1 -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '"'{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"},{\"name\":\"region\",\"type\":\"string\"}]}"}'"' http://localhost:8081/subjects/$SUBJECT/versions"
curl --silent -u $CLIENT:client1 -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"},{\"name\":\"region\",\"type\":\"string\"}]}"}' http://localhost:8081/subjects/$SUBJECT/versions

echo -e "\n\n# View new schema"
echo "curl --silent -u $CLIENT:client1 http://localhost:8081/subjects/$SUBJECT/versions/latest | jq ."
curl --silent -u $CLIENT:client1 http://localhost:8081/subjects/$SUBJECT/versions/latest | jq .


##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=../rbac_configs
restore_configs $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties $ORIGINAL_CONFIGS_DIR/schema-registry.properties $SAVE_CONFIGS_DIR/schema-registry.properties.rbac
