#!/bin/bash


################################################################################
# Overview
################################################################################
#
# Delete Kafka cluster and environment if start.sh exited prematurely
#
################################################################################

# Source library
. ../../utils/helper.sh

check_ccloud_version 0.192.0 || exit 1
check_timeout || exit 1
check_mvn || exit 1
check_expect || exit 1
check_jq || exit 1


##################################################
# Read URL, EMAIL, PASSWORD from command line arguments
#
#  Rudimentary argument processing and must be in order:
#    <url to cloud> <cloud email> <cloud password>
##################################################
URL=$1
EMAIL=$2
PASSWORD=$3
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


##################################################
# Log in to Confluent Cloud
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

ENVIRONMENT_NAME="demo-script-env"
ENVIRONMENT=$(ccloud environment list | grep $ENVIRONMENT_NAME | awk '{print $1;}')
CLUSTER_NAME="demo-kafka-cluster"
CLUSTER=$(ccloud kafka cluster list | grep $CLUSTER_NAME | awk '{print $1;}')
CLIENT_CONFIG="/tmp/client.config"

##################################################
# Cleanup
# - Delete the Kafka topics, Kafka cluster, environment, and the log files
##################################################

echo -e "\n# Cleanup: delete topics, kafka cluster, environment"
for t in $TOPIC1 $TOPIC2 $TOPIC3 connect-configs connect-offsets connect-status; do
  if ccloud kafka topic describe $t &>/dev/null; then
    echo "ccloud kafka topic delete $t"
    ccloud kafka topic delete $t
  fi
done

if [[ ! -z "$CLUSTER" ]]; then
  echo "ccloud kafka cluster delete $CLUSTER"
  ccloud kafka cluster delete $CLUSTER 1>/dev/null
fi

if [[ ! -z "$ENVIRONMENT" ]]; then
  echo "ccloud environment delete $ENVIRONMENT"
  ccloud environment delete $ENVIRONMENT 1>/dev/null
fi

rm -f "$CLIENT_CONFIG"
