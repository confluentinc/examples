#!/bin/bash


################################################################################
# Overview
################################################################################
#
# Demo the new Confluent CLI and Identiy Access Management (IAM) functionality
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
#   ./iam.sh <url to metadata server> <username> <password>
#
#   # Provide all arguments on command line, except password for which you will be prompted
#   ./iam.sh <url to metadata server> <username>
#
# Requirements:
#
#   - Local install of the new Confluent CLI (v0.96.0 or above)
#
################################################################################

# Source library
. ../utils/helper.sh

export PATH="/Users/yeva/code/bin:$PATH"
check_cli_v2 || exit 1
check_jq || exit 1


##################################################
# Read URL, USERNAME, PASSWORD from command line arguments
#
#  Rudimentary argument processing and must be in order:
#    <url to metadata server> <username> <password>
##################################################
URL=$1
USERNAME=$2
PASSWORD=$3
if [[ -z "$URL" ]]; then
  read -s -p "Metadata Server (MDS): " URL
  echo ""
fi
if [[ -z "$USERNAME" ]]; then
  read -s -p "Username: " USERNAME
  echo ""
fi
if [[ -z "$PASSWORD" ]]; then
  read -s -p "Password: " PASSWORD
  echo ""
fi


##################################################
# Log in to Metadata Server (MDS)
##################################################

echo -e "\n# Login"
OUTPUT=$(
expect <<END
  log_user 1
  spawn confluent login --url $URL
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

# Get Kafka cluster ID from ZooKeeper
KAFKA_CLUSTER_ID=$(zookeeper-shell localhost:2181 get /cluster/id 2> /dev/null | grep version | jq -r .id)
if [[ -z "$KAFKA_CLUSTER_ID" ]]; then
  echo "Failed to get Kafka cluster ID. Please troubleshoot and run again"
  exit 1
fi

# Create properties file for communicating with MDS
rm -f temp.properties
cp client.properties temp.properties
cat <<EOF >> temp.properties
sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required username="alice" password="alice-password" metadataServerUrls="$URL";
EOF

# Create a role binding for admin
# confluent iam rolebinding create \
# --principal User:admin-bob \
# --role SystemAdmin \
# --kafka-cluster-id $KAFKA_CLUSTER_ID

# Should fail
export CLASSPATH=$CONFLUENT_HOME/share/java/kafka-client-plugins-5.3.0-ce-SNAPSHOT.jar

kafka-topics \
  --bootstrap-server localhost:9092 \
  --create \
  --topic test-topic-1 \
  --replication-factor 1 \
  --partitions 3 \
  --command-config temp.properties

# Create a role binding to create topic
# confluent iam rolebinding create \
# --principal User:my-user-name \
# --role ResourceOwner \
# --resource Topic:topic1 \
# --kafka-cluster-id $KAFKA_CLUSTER_ID


##################################################
# Cleanup
#
##################################################

echo -e "\n# Cleanup"
#rm -f temp.properties
