#!/bin/bash



##################################################
# Overview
##################################################
# Demo ACL functionality in Confluent Cloud Enterprise using the new Confluent Cloud CLI
#
# DISCLAIMER:
# This script creates topics, service accounts, and ACLs
# For demo purposes only
# Use only on a non-production cluster
#
# Usage ./acl.sh <url to cloud> <cloud email> <cloud password> <cluster>
##################################################




# Source library
. ../utils/helper.sh

check_env || exit 1
check_jq || exit 1
check_running_cp 5.1 || exit 1
check_ccloud || exit 1
check_ccloud_v2 v0.25.1-30-gcd7934b-dirty-ryan || exit 1


##################################################
# Read URL, EMAIL, PASSWORD, CLUSTER
##################################################
URL=$1
EMAIL=$2
PASSWORD=$3
CLUSTER=$4
if [[ -z "$URL" ]]; then
  read -s -p "Cloud cluster: " URL
  echo ""
fi
if [[ -z "$EMAIL" ]]; then
  read -s -p "Cloud user email: " EMAIL
  echo ""
fi
if [[ -z "$PASSWORD" ]]; then
  read -s -p "Cloud user password: " PASSWORD
  echo ""
fi
if [[ -z "$CLUSTER" ]]; then
  read -s -p "Cluster id: " CLUSTER
  echo ""
fi

##################################################
# Init user
##################################################

echo -e "----------- Login -----------"
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

echo -e "----------- Set cluster -----------"
ccloud kafka cluster use $CLUSTER

echo -e "----------- Create API key and set context -----------"
OUTPUT=$(ccloud kafka cluster auth | grep "Bootstrap Servers")
BOOTSTRAP_SERVERS=$(echo $OUTPUT | awk '{print $3;}')
#echo "BOOTSTRAP_SERVERS: $BOOTSTRAP_SERVERS"


##################################################
# Produce and consume with Confluent Cloud CLI
##################################################

TOPIC1="demo-topic-1"
echo -e "----------- Create topic $TOPIC1 -----------"
echo "Creating topic $TOPIC1"
ccloud kafka topic create $TOPIC1 || true

echo -e "----------- Produce to topic $TOPIC1 -----------"
echo "Producing messages to topic $TOPIC1"
(for i in `seq 1 10`; do echo "${i}" ; done) | timeout 10s ccloud kafka topic produce $TOPIC1

echo -e "----------- Consume from topic $TOPIC1 -----------"
echo "Consuming messages from topic $TOPIC1"
timeout 10s ccloud kafka topic consume $TOPIC1


##################################################
# Create a Service Account and API key and secret
##################################################

echo -e "----------- Create service account -----------"
RANDOM_NUM=$((1 + RANDOM % 100))
SERVICE_NAME="demo-app-$RANDOM_NUM"
ccloud service-account create --name $SERVICE_NAME --description $SERVICE_NAME || true

echo -e "----------- Get service account id -----------"
SERVICE_ACCOUNT_ID=$(ccloud service-account list | grep $SERVICE_NAME | awk '{print $1;}')
echo "SERVICE_ACCOUNT_ID: $SERVICE_ACCOUNT_ID"

echo -e "----------- Create API keys for service account -----------"
OUTPUT=$(ccloud api-key create --service-account-id $SERVICE_ACCOUNT_ID --cluster $CLUSTER)
API_KEY=$(echo "$OUTPUT" | grep '| API Key' | awk '{print $5;}')
API_SECRET=$(echo "$OUTPUT" | grep "\| Secret" | awk '{print $4;}')
echo -e "----------- Sleeping 90 seconds to wait for keys to propagate -----------"
sleep 90

CLIENT_CONFIG="/tmp/client.config"
echo -e "----------- Create a file with the API key and secret at $CLIENT_CONFIG -----------"
cat <<EOF > $CLIENT_CONFIG
ssl.endpoint.identification.algorithm=https
sasl.mechanism=PLAIN
request.timeout.ms=20000
retry.backoff.ms=500
security.protocol=SASL_SSL
bootstrap.servers=${BOOTSTRAP_SERVERS}
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="${API_KEY}" password\="${API_SECRET}";
EOF


##################################################
# Java client: before and after ACLs
##################################################

echo -e "----------- Run produce client to $TOPIC1: before ACLs -----------"
mvn -q -f clients/java/pom.xml clean package
if [[ $? != 0 ]]; then
  echo "ERROR: There seems to be a BUILD FAILURE error? Please troubleshoot"
  exit 1
fi
LOG1="/tmp/log.1"
mvn -f clients/java/pom.xml exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="$CLIENT_CONFIG $TOPIC1" > $LOG1 2>&1
OUTPUT=$(grep "org.apache.kafka.common.errors.TopicAuthorizationException" $LOG1)
if [[ ! -z $OUTPUT ]]; then
  echo "Producer failed due to org.apache.kafka.common.errors.TopicAuthorizationException (expected)"
fi

echo -e "----------- Create ACLs 'CREATE' and 'WRITE' and sleeping 10 seconds to wait for ACLs to propagate -----------"
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic $TOPIC1
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic $TOPIC1
ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID
sleep 10

echo -e "----------- Run produce client to $TOPIC1: after ACLs -----------"
LOG2="/tmp/log.2"
mvn -f clients/java/pom.xml exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="$CLIENT_CONFIG $TOPIC1" > $LOG2 2>&1
OUTPUT=$(grep "BUILD SUCCESS" $LOG2)
if [[ ! -z $OUTPUT ]]; then
  echo "Producer now passes"
fi

echo -e "----------- Cleanup ACLs -----------"
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic $TOPIC1
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic $TOPIC1

##################################################
# Wildcard ACL
##################################################

TOPIC2="demo-topic-2"
echo -e "----------- Create topic $TOPIC2 -----------"
echo "Creating topic $TOPIC2"
ccloud kafka topic create $TOPIC2 || true

echo -e "----------- Create ACLs 'CREATE' and 'WRITE' with wildcard and sleeping 10 seconds to wait for ACLs to propagate -----------"
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic '*'
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'
ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID
sleep 10

echo -e "----------- Run produce client to $TOPIC2: wilcard ACLs -----------"
LOG3="/tmp/log.3"
mvn -f clients/java/pom.xml exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="$CLIENT_CONFIG $TOPIC2" > $LOG3 2>&1
OUTPUT=$(grep "BUILD SUCCESS" $LOG3)
if [[ ! -z $OUTPUT ]]; then
  echo "Producer passes"
fi

echo -e "----------- Cleanup ACLs -----------"
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic '*'
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic '*'

##################################################
# Prefix ACL
##################################################

echo -e "----------- Create ACLs 'READ' with prefix and sleeping 10 seconds to wait for ACLs to propagate -----------"
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --consumer-group java_example_group_1 --topic demo --prefix
ccloud kafka acl list --service-account-id $SERVICE_ACCOUNT_ID
sleep 10

echo -e "----------- Run consume client from $TOPIC2: prefix ACLs -----------"
LOG4="/tmp/log.4"
timeout 30s mvn -f clients/java/pom.xml exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ConsumerExample" -Dexec.args="$CLIENT_CONFIG $TOPIC2" > $LOG4 2>&1
OUTPUT=$(grep "Not authorized to access topics" $LOG4)
if [[ ! -z $OUTPUT ]]; then
  echo "Consumer passes"
fi

echo -e "----------- Cleanup ACLs -----------"
ccloud kafka acl delete --allow --service-account-id $SERVICE_ACCOUNT_ID --operation READ --consumer-group java_example_group_1 --topic $TOPIC2 --prefix


##################################################
# Cleanup
##################################################

exit

echo -e "----------- Cleanup Everything -----------"
ccloud api-key delete --api-key $API_KEY
ccloud service-account delete --service-account-id $SERVICE_ACCOUNT_ID
ccloud kafka topic delete $TOPIC1
ccloud kafka topic delete $TOPIC2
#rm -f "$LOG1"
#rm -f "$LOG2"
#rm -f "$LOG3"
#rm -f "$LOG4"
#rm -f "$CLIENT_CONFIG"
