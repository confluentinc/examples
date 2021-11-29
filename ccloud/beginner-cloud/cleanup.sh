#!/bin/bash


################################################################################
# Overview
################################################################################
#
# Delete Kafka cluster and environment if start.sh exited prematurely
#
################################################################################

# Source library
source ../../utils/helper.sh
source ../../utils/ccloud_library.sh

ccloud::validate_version_cli $CLI_MIN_VERSION || exit 1
ccloud::validate_logged_in_cli || exit 1
check_timeout || exit 1
check_mvn || exit 1
check_expect || exit 1
check_jq || exit 1

ENVIRONMENT_NAME="ccloud-stack-000000-beginner-cli"
ENVIRONMENT=$(confluent environment list | grep $ENVIRONMENT_NAME | tr -d '\*' | awk '{print $1;}')
#echo "ENVIRONMENT: $ENVIRONMENT"
CLUSTER_NAME="demo-kafka-cluster"
CLUSTER=$(confluent kafka cluster list | grep $CLUSTER_NAME | tr -d '\*' | awk '{print $1;}')
#echo "CLUSTER: $CLUSTER"
CONFIG_FILE="/tmp/client.config"
CONNECTOR_NAME="datagen_ccloud_pageviews"
CONNECTOR=$(confluent connect list | grep $CONNECTOR_NAME | tr -d '\*' | awk '{print $1;}')

##################################################
# Cleanup
# - Delete the managed Kafka connector, Kafka topics, Kafka cluster, environment, and the log files
##################################################

echo -e "\n# Cleanup: delete connector, topics, kafka cluster, environment"
if [[ ! -z "$CONNECTOR" ]]; then
    echo "confluent connect delete $CONNECTOR"
    confluent connect delete $CONNECTOR 1>/dev/null
fi

for t in $TOPIC1 $TOPIC2 $TOPIC3; do
  if confluent kafka topic describe $t &>/dev/null; then
    echo "confluent kafka topic delete $t"
    confluent kafka topic delete $t
  fi
done

if [[ ! -z "$CLUSTER" ]]; then
  echo "confluent kafka cluster delete $CLUSTER"
  confluent kafka cluster delete $CLUSTER 1>/dev/null
fi

if [[ ! -z "$ENVIRONMENT" ]]; then
  echo "confluent environment delete $ENVIRONMENT"
  confluent environment delete $ENVIRONMENT 1>/dev/null
fi

rm -f "$CONFIG_FILE"
