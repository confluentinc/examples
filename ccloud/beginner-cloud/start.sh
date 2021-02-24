#!/bin/bash


################################################################################
# Overview
################################################################################
#
# See README.md for usage and disclaimers
#
################################################################################

# Source library
source ../../utils/helper.sh
source ../../utils/ccloud_library.sh

ccloud::validate_version_ccloud_cli $CCLOUD_MIN_VERSION || exit 1
ccloud::validate_logged_in_ccloud_cli || exit 1
ccloud::prompt_continue_ccloud_demo || exit 1
check_timeout || exit 1
check_mvn || exit 1
check_jq || exit 1

##################################################
# Create a new environment and specify it as the default
##################################################

ENVIRONMENT_NAME="ccloud-stack-000000-beginner-cli"
echo -e "\n# Create a new Confluent Cloud environment $ENVIRONMENT_NAME"
echo "ccloud environment create $ENVIRONMENT_NAME -o json"
OUTPUT=$(ccloud environment create $ENVIRONMENT_NAME -o json)
if [[ $? != 0 ]]; then
  echo "ERROR: Failed to create environment $ENVIRONMENT_NAME. Please troubleshoot (maybe run ./cleanup.sh) and run again"
  exit 1
fi
echo "$OUTPUT" | jq .
ENVIRONMENT=$(echo "$OUTPUT" | jq -r ".id")
#echo $ENVIRONMENT

echo -e "\n# Specify $ENVIRONMENT as the active environment"
echo "ccloud environment use $ENVIRONMENT"
ccloud environment use $ENVIRONMENT

##################################################
# Create a new Kafka cluster and specify it as the default
##################################################

CLUSTER_NAME="${CLUSTER_NAME:-demo-kafka-cluster}"
CLUSTER_CLOUD="${CLUSTER_CLOUD:-aws}"
CLUSTER_REGION="${CLUSTER_REGION:-us-west-2}"
echo -e "\n# Create a new Confluent Cloud cluster $CLUSTER_NAME"
echo "ccloud kafka cluster create $CLUSTER_NAME --cloud $CLUSTER_CLOUD --region $CLUSTER_REGION"
OUTPUT=$(ccloud kafka cluster create $CLUSTER_NAME --cloud $CLUSTER_CLOUD --region $CLUSTER_REGION)
status=$?
echo "$OUTPUT"
if [[ $status != 0 ]]; then
  echo "ERROR: Failed to create Kafka cluster $CLUSTER_NAME. Please troubleshoot and run again"
  exit 1
fi
CLUSTER=$(echo "$OUTPUT" | grep '| Id' | awk '{print $4;}')

echo -e "\n# Specify $CLUSTER as the active Kafka cluster"
echo "ccloud kafka cluster use $CLUSTER"
ccloud kafka cluster use $CLUSTER

BOOTSTRAP_SERVERS=$(ccloud kafka cluster describe $CLUSTER -o json | jq -r ".endpoint" | cut -c 12-)
#echo "BOOTSTRAP_SERVERS: $BOOTSTRAP_SERVERS"

##################################################
# Create a user key/secret pair and specify it as the default
##################################################

echo -e "\n# Create a new API key for user"
echo "ccloud api-key create --description \"Demo credentials\" --resource $CLUSTER -o json"
OUTPUT=$(ccloud api-key create --description "Demo credentials" --resource $CLUSTER -o json)
status=$?
if [[ $status != 0 ]]; then
  echo "ERROR: Failed to create an API key.  Please troubleshoot and run again"
  exit 1
fi
echo "$OUTPUT" | jq .

API_KEY=$(echo "$OUTPUT" | jq -r ".key")
echo -e "\n# Associate the API key $API_KEY to the Kafka cluster $CLUSTER"
echo "ccloud api-key use $API_KEY --resource $CLUSTER"
ccloud api-key use $API_KEY --resource $CLUSTER

MAX_WAIT=720
echo
echo "Waiting for Confluent Cloud cluster to be ready and for credentials to propagate"
retry $MAX_WAIT ccloud::validate_ccloud_cluster_ready || exit 1
# Estimating another 60s wait still sometimes required
sleep 60
printf "\n\n"


##################################################
# Produce and consume with Confluent Cloud CLI
##################################################

TOPIC1="demo-topic-1"

echo -e "\n# Create a new Kafka topic $TOPIC1"
echo "ccloud kafka topic create $TOPIC1"
ccloud kafka topic create $TOPIC1
status=$?
if [[ $status != 0 ]]; then
  echo "ERROR: Failed to create topic $TOPIC1. Please troubleshoot and run again"
  exit 1
fi

echo -e "\n# Produce 5 messages to topic $TOPIC1"
echo '(for i in `seq 1 5`; do echo "${i}" ; done) | \'
echo "timeout 10s ccloud kafka topic produce $TOPIC1"
(for i in `seq 1 5`; do echo "${i}" ; done) | timeout 10s ccloud kafka topic produce $TOPIC1
status=$?
if [[ $status != 0 && $status != 124 ]]; then
  echo "ERROR: There seems to be a failure with 'ccloud kafka topic produce' command. Please troubleshoot"
  exit 1
fi
# Print messages to give user feedback during script run because it's not printed above
(for i in `seq 1 5`; do echo "${i}" ; done)

echo -e "\n# Consume messages from topic $TOPIC1"
echo "ccloud kafka topic consume $TOPIC1 -b"
timeout 10s ccloud kafka topic consume $TOPIC1 -b


##################################################
# Create a service account key/secret pair
# - A service account represents an application, and the service account name must be globally unique
##################################################

echo -e "\n# Create a new service account"
RANDOM_NUM=$((1 + RANDOM % 1000000))
SERVICE_NAME="demo-app-$RANDOM_NUM"
echo "ccloud service-account create $SERVICE_NAME --description $SERVICE_NAME -o json"
OUTPUT=$(ccloud service-account create $SERVICE_NAME --description $SERVICE_NAME  -o json)
echo "$OUTPUT" | jq .
SERVICE_ACCOUNT_ID=$(echo "$OUTPUT" | jq -r ".id")

echo -e "\n# Create an API key and secret for the service account $SERVICE_ACCOUNT_ID"
echo "ccloud api-key create --service-account $SERVICE_ACCOUNT_ID --resource $CLUSTER -o json"
OUTPUT=$(ccloud api-key create --service-account $SERVICE_ACCOUNT_ID --resource $CLUSTER -o json)
echo "$OUTPUT" | jq .
API_KEY_SA=$(echo "$OUTPUT" | jq -r ".key")
API_SECRET_SA=$(echo "$OUTPUT" | jq -r ".secret")

CONFIG_FILE="/tmp/client.config"
echo -e "\n# Create a local configuration file $CONFIG_FILE with Confluent Cloud connection information with the newly created API key and secret"
cat <<EOF > $CONFIG_FILE
sasl.mechanism=PLAIN
security.protocol=SASL_SSL
bootstrap.servers=${BOOTSTRAP_SERVERS}
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='${API_KEY_SA}' password='${API_SECRET_SA}';
EOF
echo "$ cat $CONFIG_FILE"
cat $CONFIG_FILE

echo -e "\n# Wait 90 seconds for the service account credentials to propagate"
sleep 90


##################################################
# Run a Java producer: before and after ACLs
# - When ACLs are enabled on your Confluent Cloud cluster, by default no client applications are authorized.
# - The following steps show the same Java producer failing at first due to 'TopicAuthorizationException'
#   and then passing once the appropriate ACLs are configured
##################################################

POM=../../clients/cloud/java/pom.xml

echo -e "\n# By default, no ACLs are configured"
echo "ccloud kafka acl list --service-account $SERVICE_ACCOUNT_ID"
ccloud kafka acl list --service-account $SERVICE_ACCOUNT_ID

echo -e "\n# Run the Java producer to $TOPIC1: before ACLs (expected to fail)"
mvn -q -f $POM clean package
if [[ $? != 0 ]]; then
  echo "ERROR: There seems to be a build failure error compiling the client code? Please troubleshoot"
  exit 1
fi
LOG1="/tmp/log.1"
echo "mvn -q -f $POM exec:java -Dexec.mainClass=\"io.confluent.examples.clients.cloud.ProducerExample\" -Dexec.args=\"$CONFIG_FILE $TOPIC1\" -Dlog4j.configuration=file:log4j.properties > $LOG1 2>&1"
mvn -q -f $POM exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="$CONFIG_FILE $TOPIC1" -Dlog4j.configuration=file:log4j.properties > $LOG1 2>&1
echo "# Check logs for 'org.apache.kafka.common.errors.TopicAuthorizationException' (expected because there are no ACLs to allow this client application)"
OUTPUT=$(grep "org.apache.kafka.common.errors.TopicAuthorizationException" $LOG1)
if [[ ! -z $OUTPUT ]]; then
  echo "PASS: Producer failed"
else
  echo "FAIL: Something went wrong, check $LOG1"
fi
echo $OUTPUT

echo -e "\n# Create ACLs for the service account"
echo "ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic $TOPIC1"
echo "ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic $TOPIC1"
ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic $TOPIC1
ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic $TOPIC1
echo
echo "ccloud kafka acl list --service-account $SERVICE_ACCOUNT_ID"
ccloud kafka acl list --service-account $SERVICE_ACCOUNT_ID
sleep 2

echo -e "\n# Run the Java producer to $TOPIC1: after ACLs"
LOG2="/tmp/log.2"
echo "mvn -q -f $POM exec:java -Dexec.mainClass=\"io.confluent.examples.clients.cloud.ProducerExample\" -Dexec.args=\"$CONFIG_FILE $TOPIC1\" -Dlog4j.configuration=file:log4j.properties > $LOG2 2>&1"
mvn -q -f $POM exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="$CONFIG_FILE $TOPIC1" -Dlog4j.configuration=file:log4j.properties > $LOG2 2>&1
echo "# Check logs for '10 messages were produced to topic'"
OUTPUT=$(grep "10 messages were produced to topic" $LOG2)
if [[ ! -z $OUTPUT ]]; then
  echo "PASS"
else
  echo "FAIL: Something went wrong, check $LOG2"
fi
cat $LOG2

echo -e "\n# Delete ACLs"
echo "ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic $TOPIC1"
echo "ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic $TOPIC1"
ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic $TOPIC1
ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic $TOPIC1



##################################################
# Run a Java producer: showcase a Prefix ACL
# - The following steps configure ACLs to match topics prefixed with a value
##################################################

TOPIC2="demo-topic-2"

echo -e "\n# Create a new Kafka topic $TOPIC2"
echo "ccloud kafka topic create $TOPIC2"
ccloud kafka topic create $TOPIC2

echo -e "\n# Create ACLs for the producer using a prefix"
PREFIX=${TOPIC2/%??/}
echo "ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic $PREFIX --prefix"
echo "ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic $PREFIX --prefix"
ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic $PREFIX --prefix
ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic $PREFIX --prefix
echo
echo "ccloud kafka acl list --service-account $SERVICE_ACCOUNT_ID"
ccloud kafka acl list --service-account $SERVICE_ACCOUNT_ID
sleep 2

echo -e "\n# Run the Java producer to $TOPIC2: prefix ACLs"
LOG3="/tmp/log.3"
echo "mvn -q -f $POM exec:java -Dexec.mainClass=\"io.confluent.examples.clients.cloud.ProducerExample\" -Dexec.args=\"$CONFIG_FILE $TOPIC2\" -Dlog4j.configuration=file:log4j.properties > $LOG3 2>&1"
mvn -q -f $POM exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="$CONFIG_FILE $TOPIC2" -Dlog4j.configuration=file:log4j.properties > $LOG3 2>&1
echo "# Check logs for '10 messages were produced to topic'"
OUTPUT=$(grep "10 messages were produced to topic" $LOG3)
if [[ ! -z $OUTPUT ]]; then
  echo "PASS"
else
  echo "FAIL: Something went wrong, check $LOG3"
fi
cat $LOG3

echo -e "\n# Delete ACLs"
echo "ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic $PREFIX --prefix"
echo "ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic $PREFIX --prefix"
ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic $PREFIX --prefix
ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic $PREFIX --prefix


##################################################
# Run a fully managed datagen_ccloud_pageviews connector
##################################################

TOPIC3="demo-topic-3"
CONNECTOR="datagen_ccloud_pageviews"
echo -e "\n# Create a new Kafka topic $TOPIC3"
echo "ccloud kafka topic create $TOPIC3"
ccloud kafka topic create $TOPIC3

echo -e "\n# Create ACLs for Connect"
echo "ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'"
ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'
echo
echo "ccloud kafka acl list --service-account $SERVICE_ACCOUNT_ID"
ccloud kafka acl list --service-account $SERVICE_ACCOUNT_ID
sleep 2

echo -e "\n# Generate env variables with Confluent Cloud connection information for Connect to use"
ccloud::generate_configs $CONFIG_FILE
echo "source delta_configs/env.delta"
source delta_configs/env.delta
cat  $CONNECTOR.json > .ignored_folder/$CONNECTOR.json
sed -i '' 's/ESN5FSNDHOFFSUEV/$CLOUD_KEY/g' .ignored_folder/$CONNECTOR.json
sed -i '' 's/nzBEyC1k7zfLvVON3vhBMQrNRjJR7pdMc2WLVyyPscBhYHkMwP6VpPVDTqhctamB/$CLOUD_SECRET/g' .ignored_folder/$CONNECTOR.json

echo -e "\n# Create a managed connector"
echo "source ../../utils/ccloud_library.sh"
source ../../utils/ccloud_library.sh

echo "ccloud::create_connector $CONNECTOR.json"
ccloud::create_connector .ignored_folder/$CONNECTOR.json

echo -e "\n# Wait for connector to be up"
echo "ccloud::wait_for_connector_up $CONNECTOR.json 300"
ccloud::wait_for_connector_up .ignored_folder/$CONNECTOR.json 300 || exit 1
##################################################
# Run a Java consumer: showcase a Wildcard ACL
# - The following steps configure ACLs to match topics using a wildcard
##################################################

CONSUMER_GROUP="demo-beginner-cloud-1"

echo -e "\n# Create ACLs for the consumer using a wildcard"
echo "ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --consumer-group $CONSUMER_GROUP"
echo "ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --topic '*'"
ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --consumer-group $CONSUMER_GROUP
ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --topic '*' 
echo
echo "ccloud kafka acl list --service-account $SERVICE_ACCOUNT_ID"
ccloud kafka acl list --service-account $SERVICE_ACCOUNT_ID
sleep 2

echo -e "\n# Run the Java consumer from $TOPIC3 (populated by kafka-connect-datagen): wildcard ACLs"
LOG4="/tmp/log.4"
echo "timeout 15s mvn -q -f $POM exec:java -Dexec.mainClass=\"io.confluent.examples.clients.cloud.ConsumerExamplePageviews\" -Dexec.args=\"$CONFIG_FILE $TOPIC3\" -Dlog4j.configuration=file:log4j.properties > $LOG4 2>&1"
timeout 15s mvn -q -f $POM exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ConsumerExamplePageviews" -Dexec.args="$CONFIG_FILE $TOPIC3" -Dlog4j.configuration=file:log4j.properties > $LOG4 2>&1
echo "# Check logs for 'Consumed record with'"
OUTPUT=$(grep "Consumed record with" $LOG4)
if [[ ! -z $OUTPUT ]]; then
  echo "PASS"
else
  echo "FAIL: Something went wrong, check $LOG4"
fi
cat $LOG4

echo -e "\n# Delete ACLs"
echo "ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --consumer-group $CONSUMER_GROUP"
echo "ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --topic '*'"
ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --consumer-group $CONSUMER_GROUP
ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --topic '*' 

echo -e "\n# Delete ACLs"
echo "ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'"
ccloud kafka acl delete --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'


##################################################
# Cleanup
# - Delete the API key, service account, Kafka topics, Kafka cluster, environment, and the log files
##################################################

echo -e "\n# Cleanup: delete connector, service-account, topics, api-keys, kafka cluster, environment"
CONNECTOR_ID=$(ccloud connector list | grep $CONNECTOR | tr -d '\*' | awk '{print $1;}')
echo "ccloud connector delete $CONNECTOR_ID"
ccloud connector delete $CONNECTOR_ID 1>/dev/null
echo "ccloud service-account delete $SERVICE_ACCOUNT_ID"
ccloud service-account delete $SERVICE_ACCOUNT_ID
for t in $TOPIC1 $TOPIC2 $TOPIC3; do
  echo "ccloud kafka topic delete $t"
  ccloud kafka topic delete $t
done
echo "ccloud api-key delete $API_KEY_SA"
ccloud api-key delete $API_KEY_SA 1>/dev/null
echo "ccloud api-key delete $API_KEY"
ccloud api-key delete $API_KEY 1>/dev/null
echo "ccloud kafka cluster delete $CLUSTER"
ccloud kafka cluster delete $CLUSTER 1>/dev/null
echo "ccloud environment delete $ENVIRONMENT"
ccloud environment delete $ENVIRONMENT 1>/dev/null

# Delete files created locally
rm -fr delta_configs
rm -f "$LOG1"
rm -f "$LOG2"
rm -f "$LOG3"
rm -f "$LOG4"
rm -f "$CONFIG_FILE"
