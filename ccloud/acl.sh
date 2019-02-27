#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_jq || exit 1
check_running_cp 5.1 || exit 1
check_ccloud || exit 1
check_ccloud_v2 || exit 1


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
echo "BOOTSTRAP_SERVERS: $BOOTSTRAP_SERVERS"


##################################################
# Produce and consume with Confluent Cloud CLI
##################################################

TOPIC="topic3"
echo -e "----------- Create topic $TOPIC -----------"
echo "Creating topic $TOPIC"
ccloud kafka topic create $TOPIC || true

echo -e "----------- Produce to topic $TOPIC -----------"
echo "Producing messages to topic $TOPIC"
(for i in `seq 1 10`; do echo "${i}" ; done) | timeout 10s ccloud kafka topic produce $TOPIC

echo -e "----------- Consume from topic $TOPIC -----------"
echo "Consuming messages from topic $TOPIC"
timeout 10s ccloud kafka topic consume $TOPIC


##################################################
# Create a Service Account and API key and secret
##################################################

echo -e "----------- Create service account -----------"
SERVICE_NAME="app1"
ccloud service-account create --name $SERVICE_NAME --description $SERVICE_NAME || true

echo -e "----------- Get service account id -----------"
SERVICE_ACCOUNT_ID=$(ccloud service-account list | grep $SERVICE_NAME | awk '{print $1;}')
echo "SERVICE_ACCOUNT_ID: $SERVICE_ACCOUNT_ID"

echo -e "----------- Create API keys for service account -----------"
OUTPUT=$(ccloud api-key create --service-account-id $SERVICE_ACCOUNT_ID --cluster $CLUSTER)
API_KEY=$(echo "$OUTPUT" | grep '| API Key' | awk '{print $5;}')
API_SECRET=$(echo "$OUTPUT" | grep "\| Secret" | awk '{print $4;}')
echo -e "----------- Sleeping 40 seconds to wait for keys to propagate -----------"
sleep 40


##################################################
# Produce and consume with a Java client
##################################################

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

echo -e "----------- Try to run produce client (it should fail) -----------"
LOG="/tmp/log.1"
mvn -f clients/java/pom.xml clean package
mvn -f clients/java/pom.xml exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="$CLIENT_CONFIG $TOPIC" 

echo -e "----------- Create CREATE and WRITE ACLs for the topic and now produce client should pass -----------"
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation CREATE --topic $TOPIC
ccloud kafka acl create --allow --service-account-id $SERVICE_ACCOUNT_ID --operation WRITE --topic $TOPIC
echo -e "----------- Sleeping 40 seconds to wait for ACLs to propagate -----------"
sleep 40
mvn -f clients/java/pom.xml exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="$CLIENT_CONFIG $TOPIC" 
echo "CLIENT_CONFIG: $CLIENT_CONFIG, TOPIC: $TOPIC"

exit

# Consume with wildcard ACL
# Try to run consume client (it should fail)
# Create READ ACL with wildcard on topic and consume client should pass
# Consume with prefixed ACL
# Create topic2
# Try to run produce client (it should fail)
# Create WRITE ACL with prefix on topic (specifically `--prefix`) and produce client should pass
