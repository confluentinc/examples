#!/bin/bash


################################################################################
# Overview
################################################################################
#
# Demo the Role Based Access Control (RBAC) and Identity Access Management (IAM) functionality
# with the new Confluent CLI
#
# Documentation accompanying this tutorial:
#
#   <>
#
# DISCLAIMER:
#
#   This is mostly for reference to see a workflow using Confluent CLI
#
#   If you choose to run it against your Kafka cluster, be aware that it:
#      - is for demo purposes only
#      - should be used only on a non-production cluster
#
# Usage:
#
#   # Provide all arguments on command line
#   ./rbac.sh
#
# Requirements:
#
#   - Local install of the new Confluent CLI (v0.96.0 or above)
#
################################################################################

# Source library
. ../../utils/helper.sh

export PATH="/Users/yeva/code/bin:$PATH"
check_env || exit 1
check_cli_v2 || exit 1
check_jq || exit 1

##################################################
# Configure MDS
##################################################

mkdir original_configs
BANNER=$(cat <<-END


------------------------------------------------------
The following lines are added by the IAM demo
------------------------------------------------------


END
)

# Kafka broker
cp $CONFLUENT_HOME/etc/kafka/server.properties original_configs/server.properties
echo "$BANNER" >> $CONFLUENT_HOME/etc/kafka/server.properties
cat delta_configs/server.properties.delta >> $CONFLUENT_HOME/etc/kafka/server.properties

# Schema Registry
cp $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties original_configs/schema-registry.properties
echo "$BANNER" >> $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties
cat delta_configs/schema-registry.properties.delta >> $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties

# Connect
#cp $CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties original_configs/connect-avro-distributed.properties
#echo "$BANNER" >> $CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties
#cat delta_configs/connect-avro-distributed.properties.delta >> $CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties

# KSQL server
#cp $CONFLUENT_HOME/etc/ksql/ksql-server.properties original_configs/ksql-server.properties
#echo "$BANNER" >> $CONFLUENT_HOME/etc/ksql/ksql-server.properties
#cat delta_configs/ksql-server.properties.delta >> $CONFLUENT_HOME/etc/ksql/ksql-server.properties

# Control Center
#cp $CONFLUENT_HOME/etc/confluent-control-center/control-center-dev.properties original_configs/control-center-dev.properties
#echo $BANNER >> $CONFLUENT_HOME/etc/confluent-control-center/control-center-dev.properties
#cat delta_configs/control-center-dev.properties.delta >> $CONFLUENT_HOME/etc/confluent-control-center/control-center-dev.properties

# Copy login.properties
cp login.properties /tmp/login.properties

# Generate keys
openssl genrsa -out /tmp/tokenKeypair.pem 2048 
openssl rsa -in /tmp/tokenKeypair.pem -outform PEM -pubout -out /tmp/tokenPublicKey.pem

confluent local destroy
confluent local start kafka

##################################################
# Initialize
##################################################
USERNAME=mds
PASSWORD=mds1
BOOTSTRAP_SERVER=localhost:9092
MDS=http://localhost:8090
ADMIN_SYSTEM=MySystemAdmin
CLIENT=client
ADMIN_SCHEMA_REGISTRY=sr

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
# Grant the principal User:$ADMIN_SYSTEM the SystemAdmin role # access to different service clusters
##################################################

# Grant access to the Kafka cluster
get_cluster_id_kafka
echo -e "\n# Bind the principal User:$ADMIN_SYSTEM to the SystemAdmin role access to the Kafka cluster"
echo "confluent iam rolebinding create --principal User:$ADMIN_SYSTEM --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$ADMIN_SYSTEM --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# List the role bindings for User:$ADMIN_SYSTEM"
echo "confluent iam rolebinding list --principal User:$ADMIN_SYSTEM --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:$ADMIN_SYSTEM --kafka-cluster-id $KAFKA_CLUSTER_ID

##################################################
# Topics: create, producer, consume
# - Bind the principal User:$CLIENT to the ResourceOwner role for Topic:$TOPIC
# - Create topic $TOPIC
# - List topics, it should show only topic $TOPIC
# - Produce to topic $TOPIC
# - Create a role binding to the resource Group:console-consumer-
# - Consume from topic $TOPIC from RBAC endpoint
# - Consume from topic $TOPIC from PLAINTEXT endpoint
##################################################
TOPIC=test-topic-1
echo -e "\n# Create a topic called $TOPIC"

echo -e "\n# Try to create topic $TOPIC, before authorization (should fail)"
echo "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --replication-factor 1 --partitions 3 --command-config delta_configs/client.properties.delta"
OUTPUT=$(kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --replication-factor 1 --partitions 3 --command-config delta_configs/client.properties.delta)
if [[ $OUTPUT =~ "org.apache.kafka.common.errors.TopicAuthorizationException" ]]; then
  echo "PASS: Topic creation failed due to org.apache.kafka.common.errors.TopicAuthorizationException (expected because User:$CLIENT is not allowed to create topics)"
else
  echo "FAIL: Something went wrong, check output"
fi

echo -e "\n# Bind the principal User:$CLIENT to the ResourceOwner role for Topic:$TOPIC"
echo "confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Topic:$TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Topic:$TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Try to create topic $TOPIC, after authorization (should pass)"
echo "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --replication-factor 1 --partitions 3 --command-config delta_configs/client.properties.delta"
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --replication-factor 1 --partitions 3 --command-config delta_configs/client.properties.delta

echo -e "\n# List topics, it should show only topic $TOPIC"
echo "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --list --command-config delta_configs/client.properties.delta"
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --list --command-config delta_configs/client.properties.delta

echo -e "\n# Produce to topic $TOPIC"
echo "seq 10 | confluent local produce $TOPIC -- --producer.config delta_configs/client.properties.delta"
seq 10 | confluent local produce $TOPIC -- --producer.config delta_configs/client.properties.delta

echo -e "\n# Consume from topic $TOPIC from RBAC endpoint (should fail)"
echo "confluent local consume test-topic-1 -- --consumer.config delta_configs/client.properties.delta --from-beginning --max-messages 10"
OUTPUT=$(confluent local consume test-topic-1 -- --consumer.config delta_configs/client.properties.delta --from-beginning --max-messages 10 2>&1)
if [[ $OUTPUT =~ "org.apache.kafka.common.errors.GroupAuthorizationException" ]]; then
  echo "PASS: Consume failed due to org.apache.kafka.common.errors.GroupAuthorizationException (expected because User:$CLIENT is not allowed access to consumer groups)"
else
  echo "FAIL: Something went wrong, check output"
fi

echo -e "#\n Create a role binding to the resource Group:console-consumer-"
echo "confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Group:console-consumer- --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:$CLIENT --role ResourceOwner --resource Group:console-consumer- --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

echo -e "\n# Consume from topic $TOPIC from RBAC endpoint (should pass)"
echo "confluent local consume test-topic-1 -- --consumer.config delta_configs/client.properties.delta --from-beginning --max-messages 10"
confluent local consume test-topic-1 -- --consumer.config delta_configs/client.properties.delta --from-beginning --max-messages 10

echo -e "\n# Consume from topic $TOPIC from PLAINTEXT endpoint"
echo "confluent local consume test-topic-1 -- --bootstrap-server localhost:9093 --from-beginning --max-messages 10"
confluent local consume test-topic-1 -- --bootstrap-server localhost:9093 --from-beginning --max-messages 10


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

echo -e "\n# Cleanup"
rm /tmp/tokenKeyPair.pem
rm /tmp/tokenPublicKey.pem
rm /tmp/login.properties

cp original_configs/server.properties $CONFLUENT_HOME/etc/kafka/server.properties
rm original_configs/server.properties
cp original_configs/schema-registry.properties $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties
rm original_configs/schema-registry.properties
#cp original_configs/connect-avro-distributed.properties $CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties
#rm original_configs/connect-avro-distributed.properties
#cp original_configs/ksql-server.properties $CONFLUENT_HOME/etc/ksql/ksql-server.properties
#rm original_configs/ksql-server.properties
#cp original_configs/control-center-dev.properties $CONFLUENT_HOME/etc/confluent-control-center/control-center-dev.properties
#rm original_configs/control-center-dev.properties
