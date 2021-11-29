#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

# Source demo-specific configurations
source config/demo.cfg

#################################################################
# Source Confluent Cloud configurations
#################################################################
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

#################################################################
# Confluent Cloud ksqlDB application
#################################################################
echo -e "\nConfluent Cloud ksqlDB application\n"
ccloud::validate_ksqldb_up "$KSQLDB_ENDPOINT" || exit 1
ccloud::validate_credentials_ksqldb "$KSQLDB_ENDPOINT" "$CONFIG_FILE" "$KSQLDB_BASIC_AUTH_USER_INFO" || exit 1

# Create required topics and ACLs
echo -e "Create output topics $KAFKA_TOPIC_NAME_OUT1 and $KAFKA_TOPIC_NAME_OUT2, and ACLs to allow the ksqlDB application to run\n"
confluent kafka topic create $KAFKA_TOPIC_NAME_OUT1
confluent kafka topic create $KAFKA_TOPIC_NAME_OUT2
ksqlDBAppId=$(confluent ksql app list | grep "$KSQLDB_ENDPOINT" | awk '{print $1}')
confluent ksql app configure-acls $ksqlDBAppId $KAFKA_TOPIC_NAME_IN $KAFKA_TOPIC_NAME_OUT1 $KAFKA_TOPIC_NAME_OUT2
SERVICE_ACCOUNT_ID=$(ccloud:get_service_account_from_current_cluster_name)
confluent kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic $KAFKA_TOPIC_NAME_OUT1
confluent kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic $KAFKA_TOPIC_NAME_OUT2

# Submit KSQL queries
echo -e "\nSubmit KSQL queries\n"
properties='"ksql.streams.auto.offset.reset":"earliest","ksql.streams.cache.max.bytes.buffering":"0"'
while read ksqlCmd; do
  echo -e "\n$ksqlCmd\n"
  response=$(curl -X POST $KSQLDB_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQLDB_BASIC_AUTH_USER_INFO \
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
done <statements.sql
echo -e "\nSleeping 20 seconds after submitting KSQL queries\n"
sleep 20

exit 0
