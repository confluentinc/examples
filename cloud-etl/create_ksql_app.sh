#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
. ../utils/helper.sh

# Source demo-specific configurations
source config/demo.cfg

#################################################################
# Source CCloud configurations
#################################################################
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

#################################################################
# Confluent Cloud KSQL application
#################################################################
echo -e "\nConfluent Cloud KSQL application\n"
validate_ccloud_ksql "$KSQL_ENDPOINT" "$CONFIG_FILE" "$KSQL_BASIC_AUTH_USER_INFO" || exit 1

# Create required topics and ACLs
echo -e "Create output topics $KAFKA_TOPIC_NAME_OUT1 and $KAFKA_TOPIC_NAME_OUT2, and ACLs to allow the KSQL application to run\n"
ccloud kafka topic create $KAFKA_TOPIC_NAME_OUT1
ccloud kafka topic create $KAFKA_TOPIC_NAME_OUT2
ksqlAppId=$(ccloud ksql app list | grep "$KSQL_ENDPOINT" | awk '{print $1}')
ccloud ksql app configure-acls $ksqlAppId $KAFKA_TOPIC_NAME_IN $KAFKA_TOPIC_NAME_OUT1 $KAFKA_TOPIC_NAME_OUT2
ccloud kafka acl create --allow --service-account-id $(ccloud service-account list | grep $ksqlAppId | awk '{print $1;}') --operation WRITE --topic $KAFKA_TOPIC_NAME_OUT1
ccloud kafka acl create --allow --service-account-id $(ccloud service-account list | grep $ksqlAppId | awk '{print $1;}') --operation WRITE --topic $KAFKA_TOPIC_NAME_OUT2

# Submit KSQL queries
echo -e "\nSubmit KSQL queries\n"
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
    echo -e "\nERROR: KSQL command '$ksqlCmd' did not include \"SUCCESS\" in the response.  Please troubleshoot."
    exit 1
  fi
done <ksql.commands
echo -e "\nSleeping 20 seconds after submitting KSQL queries\n"
sleep 20

exit 0
