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
#cp $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties original_configs/schema-registry.properties
#echo "$BANNER" >> $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties
#cat delta_configs/schema-registry.properties.delta >> $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties

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
# Grant the principal User:MySystemAdmin 
# the SystemAdmin role
# access to different service clusters
#
##################################################

# Access to the Kafka cluster
get_cluster_id_kafka
echo "confluent iam rolebinding create --principal User:MySystemAdmin --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding create --principal User:MySystemAdmin --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID

# List role bindings for User:MySystemAdmin
echo "confluent iam rolebinding list --principal User:MySystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID"
confluent iam rolebinding list --principal User:MySystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID

##################################################
# Create a topic
#
##################################################
TOPIC=test-topic-1
echo "Create a topic called $TOPIC"

echo "  1st attempt to create the topic fails"
kafka-topics \
  --bootstrap-server $BOOTSTRAP_SERVER \
  --create \
  --topic $TOPIC \
  --replication-factor 1 \
  --partitions 3 \
  --command-config delta_configs/client.properties.delta

echo "  Create a role binding to the resource Topic:$TOPIC"
confluent iam rolebinding create \
 --principal User:client \
 --role ResourceOwner \
 --resource Topic:$TOPIC \
 --kafka-cluster-id $KAFKA_CLUSTER_ID

echo "  2nd attempt to create the topic succeeds"
kafka-topics \
  --bootstrap-server $BOOTSTRAP_SERVER \
  --create \
  --topic $TOPIC \
  --replication-factor 1 \
  --partitions 3 \
  --command-config delta_configs/client.properties.delta

echo "  Listing topics shows only topic $TOPIC"
kafka-topics \
  --bootstrap-server $BOOTSTRAP_SERVER \
  --list --command-config delta_configs/client.properties.delta


##################################################
# Produce/consume to a topic
#
##################################################
echo "Produce to topic $TOPIC"
seq 10 | confluent local produce $TOPIC -- --producer.config delta_configs/client.properties.delta

echo "Consume from topic $TOPIC (RBAC endpoint)"
confluent local consume test-topic-1 -- --consumer.config delta_configs/client.properties.delta --from-beginning --max-messages 10

echo "Create a role binding to the resource Group:console-consumer-"
confluent iam rolebinding create \
 --principal User:client \
 --role ResourceOwner \
 --resource Group:console-consumer- \
 --prefix \
 --kafka-cluster-id $KAFKA_CLUSTER_ID

echo "Consume from topic $TOPIC (RBAC endpoint)"
confluent local consume test-topic-1 -- --consumer.config delta_configs/client.properties.delta --from-beginning --max-messages 10

echo "Consume from topic $TOPIC (PLAINTEXT endpoint)"
confluent local consume test-topic-1 -- --bootstrap-server localhost:9093 --from-beginning --max-messages 10

##################################################
# Cleanup
#
##################################################

echo -e "\n# Cleanup"
rm /tmp/tokenKeyPair.pem
rm /tmp/tokenPublicKey.pem
rm /tmp/login.properties

cp original_configs/server.properties $CONFLUENT_HOME/etc/kafka/server.properties
rm original_configs/server.properties
#cp original_configs/schema-registry.properties $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties
#rm original_configs/schema-registry.properties
#cp original_configs/connect-avro-distributed.properties $CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties
#rm original_configs/connect-avro-distributed.properties
#cp original_configs/ksql-server.properties $CONFLUENT_HOME/etc/ksql/ksql-server.properties
#rm original_configs/ksql-server.properties
#cp original_configs/control-center-dev.properties $CONFLUENT_HOME/etc/confluent-control-center/control-center-dev.properties
#rm original_configs/control-center-dev.properties
