#!/bin/bash

#################################################################
# Initialization
#################################################################
# Source library
. ../utils/helper.sh

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
echo -e "Configure ACLs for Confluent Cloud KSQL"
ksqlAppId=$(ccloud ksql app list | grep "$KSQL_ENDPOINT" | awk '{print $1}')
ccloud ksql app configure-acls $ksqlAppId pageviews users USERS_ORIGINAL PAGEVIEWS_FEMALE PAGEVIEWS_FEMALE_LIKE_89 PAGEVIEWS_REGIONS
for topic in USERS_ORIGINAL PAGEVIEWS_FEMALE PAGEVIEWS_FEMALE_LIKE_89 PAGEVIEWS_REGIONS; do
  echo "Creating topic $topic and ACL permitting KSQL to write to it"
  ccloud kafka topic create $topic
  ccloud kafka acl create --allow --service-account $(ccloud service-account list | grep $ksqlAppId | awk '{print $1;}') --operation WRITE --topic $topic
done

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
done <statements.sql

exit 0
