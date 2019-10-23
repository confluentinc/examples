#!/bin/bash


################################################################################
# Overview
################################################################################
#
# Demo the new Confluent Cloud CLI and Access Control List (ACL) functionality
# in your Confluent Cloud cluster
#
# Documentation accompanying this tutorial:
#
#   https://docs.confluent.io/current/cloud/access-management/user-service-example.html
#   https://docs.confluent.io/current/cloud/cli/install.html#ccloud-install-cli
#
# DISCLAIMER:
#
#   This demo is for reference purposes only and should be used 
#   	to see a workflow using Confluent Cloud CLI
#
#   If you choose to run it against your Confluent Cloud cluster, be aware that it:
#      - creates and deletes topics, service accounts, API keys, and ACLs
#      - is for demo purposes only
#      - should be used only on a non-production cluster
#
# Usage:
#
#   # Provide all arguments on command line
#   ./acl.sh <url to cloud> <cloud email> <environment> <cluster> <cloud password>
#
#   # Provide all arguments on command line, except password for which you will be prompted
#   ./acl.sh <url to cloud> <cloud email> <environment> <cluster>
#
# Requirements:
#
#   - Access to a Confluent Cloud cluster
#   - Local install of the new Confluent Cloud CLI (v0.185.0 or above)
#   - Docker and Docker Compose
#   - `timeout` installed on your host
#   - `mvn` installed on your host
#
################################################################################

# Source library
. ../../utils/helper.sh

check_ccloud_version || exit 1
check_timeout || exit 1
check_mvn || exit 1
check_expect || exit 1

##################################################
# Read URL, EMAIL, ENVIRONMENT, CLUSTER, PASSWORD from command line arguments
#
#  Rudimentary argument processing and must be in order:
#    <url to cloud> <cloud email> <environment> <cluster> <cloud password>
##################################################
URL=$1
EMAIL=$2
ENVIRONMENT=$3
CLUSTER=$4
PASSWORD=$5
if [[ -z "$URL" ]]; then
  read -s -p "Cloud cluster: " URL
  echo ""
fi
if [[ -z "$EMAIL" ]]; then
  read -s -p "Cloud user email: " EMAIL
  echo ""
fi
if [[ -z "$ENVIRONMENT" ]]; then
  read -s -p "Environment id: " ENVIRONMENT
  echo ""
fi
if [[ -z "$CLUSTER" ]]; then
  read -s -p "Cluster id: " CLUSTER
  echo ""
fi
if [[ -z "$PASSWORD" ]]; then
  read -s -p "Cloud user password: " PASSWORD
  echo ""
fi


##################################################
# Log in, specify active cluster, and create a user key/secret 
##################################################

echo -e "\n# Login"
OUTPUT=$(
expect <<END
  log_user 1
  spawn ccloud login --url $URL
  expect "Email: "
  send "$EMAIL\r";
  expect "Password: "
  send "$PASSWORD\r";
  expect "Logged in as "
  set result $expect_out(buffer)
END
)
echo "$OUTPUT"
if [[ ! "$OUTPUT" =~ "Logged in as" ]]; then
  echo "Failed to log into your cluster.  Please check all parameters and run again"
  exit 1
fi

echo -e "\n# Specify active environment to use"
echo "ccloud environment use $ENVIRONMENT"
ccloud environment use $ENVIRONMENT
if [[ $? != 0 ]]; then
  echo "Failed to set environment $ENVIRONMENT.  Please troubleshoot, confirm environment, and run again"
  exit 1
fi

echo -e "\n# Specify active cluster to use"
echo "ccloud kafka cluster use $CLUSTER"
ccloud kafka cluster use $CLUSTER
if [[ $? != 0 ]]; then
  echo "Failed to set cluster. Please troubleshoot, confirm cluster id, and run again"
  exit 1
fi

echo -e "\n# Create API key for $EMAIL"
echo "ccloud api-key create --description \"Demo API key and secret for $EMAIL\""
OUTPUT=$(ccloud api-key create --description "Demo API key and secret for $EMAIL")
if [[ $? != 0 ]]; then
  echo "Failed to create an API key.  Please troubleshoot and run again"
  exit 1
fi
API_KEY=$(echo "$OUTPUT" | grep '| API Key' | awk '{print $5;}')
#echo "API_KEY: $API_KEY"

echo -e "\n# Specify active API key that was just created"
echo "ccloud api-key use $API_KEY"
ccloud api-key use $API_KEY

OUTPUT=$(ccloud kafka cluster describe $CLUSTER)
if [[ $? != 0 ]]; then
  echo "Failed to describe the cluster $CLUSTER (does it exist in this environment?).  Please troubleshoot and run again"
  exit 1
fi
BOOTSTRAP_SERVERS=$(echo "$OUTPUT" | grep "Endpoint" | grep SASL_SSL | awk '{print $4;}' | cut -c 12-)
#echo "BOOTSTRAP_SERVERS: $BOOTSTRAP_SERVERS"


##################################################
# Create a Service Account and API key and secret
#
#   A service account represents an application access 
##################################################

echo -e "\n# Create a new service account"
RANDOM_NUM=$((1 + RANDOM % 100))
SERVICE_NAME="demo-app-$RANDOM_NUM"
echo "ccloud service-account create $SERVICE_NAME --description $SERVICE_NAME"
ccloud service-account create $SERVICE_NAME --description $SERVICE_NAME || true
SERVICE_ACCOUNT_ID=$(ccloud service-account list | grep $SERVICE_NAME | awk '{print $1;}')

echo -e "\n# Create an API key and secret for the new service account"
echo "ccloud api-key create --service-account-id $SERVICE_ACCOUNT_ID --resource $CLUSTER"
OUTPUT=$(ccloud api-key create --service-account-id $SERVICE_ACCOUNT_ID --resource $CLUSTER)
API_KEY_SA=$(echo "$OUTPUT" | grep '| API Key' | awk '{print $5;}')
API_SECRET_SA=$(echo "$OUTPUT" | grep '| Secret' | awk '{print $4;}')

echo -e "\n# Sleeping 90 seconds to wait for the user and service account key and secret to propagate"
sleep 90

CLIENT_CONFIG="/tmp/client.config"
echo -e "\n# Create a local configuration file $CLIENT_CONFIG for the client to connect to Confluent Cloud with the newly created API key and secret"
echo "Writing to $CLIENT_CONFIG"
cat <<EOF > $CLIENT_CONFIG
ssl.endpoint.identification.algorithm=https
sasl.mechanism=PLAIN
security.protocol=SASL_SSL
bootstrap.servers=${BOOTSTRAP_SERVERS}
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="${API_KEY_SA}" password\="${API_SECRET_SA}";
EOF


##################################################
# Produce and consume with Confluent Cloud CLI
##################################################

TOPIC1="demo-topic-1"

echo -e "\n# Check if topic $TOPIC1 exists"
echo "ccloud kafka topic create $TOPIC1 --dry-run 2>/dev/null"
ccloud kafka topic create $TOPIC1 --dry-run 2>/dev/null
if [[ $? == 0 ]]; then
  echo -e "\n# Create topic $TOPIC1"
  echo "ccloud kafka topic create $TOPIC1"
  ccloud kafka topic create $TOPIC1 || true
else
  echo "Topic $TOPIC1 already exists"
fi

echo -e "\n# Produce to topic $TOPIC1"
echo '(for i in `seq 1 10`; do echo "${i}" ; done) | \'
echo "timeout 10s ccloud kafka topic produce $TOPIC1"
(for i in `seq 1 10`; do echo "${i}" ; done) | timeout 10s ccloud kafka topic produce $TOPIC1
status=$?
if [[ $status != 0 && $status != 124 ]]; then
  echo "ERROR: There seems to be a failure with 'ccloud kafka topic produce' command. Please troubleshoot"
  exit 1
fi

echo -e "\n# Consume from topic $TOPIC1"
echo "ccloud kafka topic consume $TOPIC1 -b"
timeout 10s ccloud kafka topic consume $TOPIC1 -b


##################################################
# Java client: before and after ACLs
#
# When ACLs are enabled on your Confluent Cloud cluster,
# by default no client applications are authorized.
#
# The following steps show the same Java producer failing at first due to
# `TopicAuthorizationException` and then passing once the appropriate
# ACLs are configured
##################################################

POM=../../clients/cloud/java/pom.xml

echo -e "\n# By default, no ACLs are configured"
echo "ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID"
ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID

echo -e "\n# Run the Java producer to $TOPIC1: before ACLs"
mvn -q -f $POM clean package
if [[ $? != 0 ]]; then
  echo "ERROR: There seems to be a build failure error compiling the client code? Please troubleshoot"
  exit 1
fi
LOG1="/tmp/log.1"
mvn -f $POM exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="$CLIENT_CONFIG $TOPIC1" > $LOG1 2>&1
OUTPUT=$(grep "org.apache.kafka.common.errors.TopicAuthorizationException" $LOG1)
if [[ ! -z $OUTPUT ]]; then
  echo "PASS: Producer failed due to org.apache.kafka.common.errors.TopicAuthorizationException (expected because there are no ACLs to allow this client application)"
else
  echo "FAIL: Something went wrong, check $LOG1"
fi

echo -e "\n# Create ACLs for the service account"
echo "ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic $TOPIC1"
echo "ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic $TOPIC1"
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic $TOPIC1
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic $TOPIC1
echo "ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID"
ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID
sleep 2

echo -e "\n# Run the Java producer to $TOPIC1: after ACLs"
LOG2="/tmp/log.2"
mvn -f $POM exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="$CLIENT_CONFIG $TOPIC1" > $LOG2 2>&1
OUTPUT=$(grep "BUILD SUCCESS" $LOG2)
if [[ ! -z $OUTPUT ]]; then
  echo "PASS: Producer works"
else
  echo "FAIL: Something went wrong, check $LOG2"
fi

echo -e "\n# Delete ACLs"
echo "ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic $TOPIC1"
echo "ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic $TOPIC1"
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic $TOPIC1
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic $TOPIC1



##################################################
# Prefix ACL
#
# The following steps configure ACLs to match topics prefixed with a value
##################################################

TOPIC2="demo-topic-2"
echo -e "\n# Create topic $TOPIC2"
echo "ccloud kafka topic create $TOPIC2"
ccloud kafka topic create $TOPIC2 || true

echo -e "\n# Create ACLs for the producer using a prefix"
PREFIX=${TOPIC2/%??/}
echo "ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic $PREFIX --prefix"
echo "ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic $PREFIX --prefix"
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic $PREFIX --prefix
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic $PREFIX --prefix
echo "ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID"
ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID
sleep 2

echo -e "\n# Run the Java producer to $TOPIC2: prefix ACLs"
LOG3="/tmp/log.3"
mvn -f $POM exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="$CLIENT_CONFIG $TOPIC2" > $LOG3 2>&1
OUTPUT=$(grep "BUILD SUCCESS" $LOG3)
if [[ ! -z $OUTPUT ]]; then
  echo "PASS: Producer works"
else
  echo "FAIL: Something went wrong, check $LOG3"
fi

echo -e "\n# Delete ACLs"
echo "ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic $PREFIX --prefix"
echo "ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic $PREFIX --prefix"
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic $PREFIX --prefix
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic $PREFIX --prefix


##################################################
# Wildcard ACL
#
# The following steps configure ACLs to match topics using a wildcard
##################################################

CONSUMER_GROUP="demo-consumer-1"

echo -e "\n# Create ACLs for the consumer using a wildcard"
echo "ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --consumer-group $CONSUMER_GROUP"
echo "ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --topic '*'"
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --consumer-group $CONSUMER_GROUP
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --topic '*' 
echo "ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID"
ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID
sleep 2

echo -e "\n# Run the Java consumer from $TOPIC2: wildcard ACLs"
LOG4="/tmp/log.4"
timeout 15s mvn -f $POM exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ConsumerExample" -Dexec.args="$CLIENT_CONFIG $TOPIC2" > $LOG4 2>&1
OUTPUT=$(grep "Successfully joined group with" $LOG4)
if [[ ! -z $OUTPUT ]]; then
  echo "PASS: Consumer works"
else
  echo "FAIL: Something went wrong, check $LOG4"
fi

echo -e "\n# Delete ACLs"
echo "ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --consumer-group $CONSUMER_GROUP"
echo "ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --topic '*'"
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --consumer-group $CONSUMER_GROUP
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --topic '*' 


##################################################
# Connect and Connectors
#
#   Confluent Hub: https://www.confluent.io/hub/
##################################################

../../ccloud/ccloud-generate-cp-configs.sh $CLIENT_CONFIG
source delta_configs/env.delta

echo -e "\n# Create ACLs for Connect"
echo "ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic '*'"
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic '*'
echo "ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'"
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'
echo "ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --topic '*'"
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --topic '*'
echo "ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --consumer-group connect"
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --consumer-group connect
echo "ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID"
ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID
sleep 2

echo "Run a Connect container with the kafka-connect-datagen plugin"
docker-compose up -d
echo -e "\n# Sleeping 60 seconds to wait for Connect to start"
sleep 60

echo -e "\n# Check if topic pageviews exists"
echo "ccloud kafka topic create pageviews --dry-run 2>/dev/null"
ccloud kafka topic create pageviews --dry-run 2>/dev/null
if [[ $? == 0 ]]; then
  echo -e "\n# Create topic pageviews"
  echo "ccloud kafka topic create pageviews"
  ccloud kafka topic create pageviews || true
else
  echo "Topic pageviews already exists"
fi

echo "Post the configuration for the kafka-connect-datagen connector"
HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "datagen-pageviews",
  "config": {
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "kafka.topic": "pageviews",
    "quickstart": "pageviews",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "max.interval": 1000,
    "iterations": 1000000000,
    "tasks.max": "1"
  }
}
EOF
)
echo "curl -X POST -H \"${HEADER}\" --data \"${DATA}\" http://localhost:8083/connectors"
curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors
if [[ $? != 0 ]]; then
  echo "ERROR: Could not successfully submit connector. Please troubleshoot Connect."
  #exit $?
fi

echo -e "\n# Sleeping 30 seconds to wait for kafka-connect-datagen to start producing messages"
sleep 30

echo -e "\n# Consume from topic pageviews"
echo "ccloud kafka topic consume pageviews"
timeout 10s ccloud kafka topic consume pageviews

echo -e "\n# Stop Docker and Delete ACLs"
echo "docker-compose down"
docker-compose down
echo "ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic '*'"
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic '*'
echo "ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'"
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'
echo "ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --topic '*'"
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --topic '*'
echo "ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --consumer-group connect"
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --consumer-group connect


##################################################
# Cleanup
#
# Delete the API key, service account, Kafka topics, and some of the local files
##################################################

echo -e "\n# Cleanup service-account, topics, and api-keys"
echo "ccloud service-account delete $SERVICE_ACCOUNT_ID"
ccloud service-account delete $SERVICE_ACCOUNT_ID
for t in $TOPIC1 $TOPIC2 connect-configs connect-offsets connect-status pageviews; do
  echo "ccloud kafka topic delete $t"
  ccloud kafka topic delete $t
done
echo "ccloud api-key delete $API_KEY_SA"
ccloud api-key delete $API_KEY_SA
echo "ccloud api-key delete $API_KEY"
ccloud api-key delete $API_KEY

# Delete files created locally
rm -fr delta/configs
rm -f "$LOG1"
rm -f "$LOG2"
rm -f "$LOG3"
rm -f "$LOG4"
rm -f "$CLIENT_CONFIG"
