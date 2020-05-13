#!/bin/bash

#########################################
# This script uses real Confluent Cloud resources.
# To avoid unexpected charges, carefully evaluate the cost of resources before launching the script and ensure all resources are destroyed after you are done running it.
#########################################


# Source library
. ../utils/helper.sh

check_ccloud_version 1.0.0 \
  && print_pass "ccloud version ok" \
  || exit 1
check_ccloud_logged_in \
  && print_pass "logged into ccloud CLI" \
  || exit 1

wget -O docker-compose.yml https://raw.githubusercontent.com/confluentinc/cp-all-in-one/${CONFLUENT_RELEASE_TAG_OR_BRANCH}/cp-all-in-one-cloud/docker-compose.yml

echo ====== Confirm
prompt_continue_cloud_demo || exit 1
read -p "Do you acknowledge this script creates a Confluent Cloud KSQL app (hourly charges may apply)? [y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1; fi

echo
echo ====== Create new Confluent Cloud stack
cloud_create_demo_stack true
SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
export CONFIG_FILE=$CONFIG_FILE
check_ccloud_config $CONFIG_FILE || exit 1
../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

# Pre-flight check of Confluent Cloud credentials specified in $CONFIG_FILE
MAX_WAIT=720
echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud KSQL cluster to be UP"
retry $MAX_WAIT check_ccloud_ksql_endpoint_ready $KSQL_ENDPOINT || exit 1
print_pass "Confluent Cloud KSQL is UP"
ccloud_demo_preflight_check $CLOUD_KEY $CONFIG_FILE || exit 1

ccloud kafka topic create _confluent-monitoring
ccloud kafka topic create pageviews
ccloud kafka topic create users

docker-compose up -d connect

# Verify Kafka Connect worker has started
MAX_WAIT=120
echo "Waiting up to $MAX_WAIT seconds for Kafka Connect to start"
retry $MAX_WAIT check_connect_up connect || exit 1
sleep 2 # give connect an exta moment to fully mature
print_pass "Kafka Connect has started"
echo

# Configure datagen connectors
. ./connectors/submit_datagen_pageviews_config_cloud.sh
. ./connectors/submit_datagen_users_config_cloud.sh

echo
echo "Sleeping 30 seconds to give kafka-connect-datagen a chance to start producing messages"
sleep 30

# Run the KSQL queries
echo -e "\nSubmit KSQL queries\n"
ksqlAppId=$(ccloud ksql app list | grep "$KSQL_ENDPOINT" | awk '{print $1}')
ccloud ksql app configure-acls $ksqlAppId pageviews users PAGEVIEWS_FEMALE pageviews_female_like_89 PAGEVIEWS_REGIONS
properties='"ksql.streams.auto.offset.reset":"earliest","ksql.streams.cache.max.bytes.buffering":"0"'
while read ksqlCmd; do
  echo -e "\n$ksqlCmd\n"
  response=$(curl -X POST $KSQL_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQL_BASIC_AUTH_USER_INFO \
       --silent \
       -d @<(cat <<EOF
{
  "ksql": "$ksqlCmd",
  "streamsProperties": {$properties}
}
EOF
))
  echo $response
  if [[ ! "$response" =~ "SUCCESS" ]]; then
    echo -e "\nWARN: KSQL command '$ksqlCmd' did not include \"SUCCESS\" in the response. Please troubleshoot."
  fi
done <statements.sql

echo "-----------------------------------------------------------"

echo
echo "Local client configuration file written to $CONFIG_FILE"
echo
echo "Confluent Cloud KSQL is running and accruing charges. To destroy this demo run and verify ->"
echo "    ./stop-docker-cloud.sh $CONFIG_FILE"
echo
