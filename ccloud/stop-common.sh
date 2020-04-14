#!/bin/bash

# Source library 
. ../utils/helper.sh

check_env || exit 1

# File with Confluent Cloud configuration parameters: example template
#   $ cat ~/.ccloud/config
#   bootstrap.servers=<BROKER ENDPOINT>
#   ssl.endpoint.identification.algorithm=https
#   security.protocol=SASL_SSL
#   sasl.mechanism=PLAIN
#   sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
#   # Confluent Cloud Schema Registry
#   basic.auth.credentials.source=USER_INFO
#   schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
#   schema.registry.url=https://<SR ENDPOINT>
#   # Confluent Cloud KSQL
#   ksql.endpoint=https://<KSQL ENDPOINT>
#   ksql.basic.auth.user.info=<KSQL API KEY>:<KSQL API SECRET>
export CONFIG_FILE=~/.ccloud/config

check_ccloud_config $CONFIG_FILE || exit 1
check_ccloud_version 0.239.0 || exit 1
check_ccloud_logged_in || exit 1

#################################################################
# Generate CCloud configurations
#################################################################

DELTA_CONFIGS_DIR="delta_configs"
./ccloud-generate-cp-configs.sh $CONFIG_FILE > /dev/null
source delta_configs/env.delta

# Set Kafka cluster
ccloud_cli_set_kafka_cluster_use $CLOUD_KEY $CONFIG_FILE || exit 1

# Clean up KSQL
echo "Clean up KSQL"
validate_ccloud_ksql "$KSQL_ENDPOINT" "$CONFIG_FILE" "$KSQL_BASIC_AUTH_USER_INFO" || exit 1
# Terminate queries first
ksqlCmd="show queries;"
echo -e "\n\n$ksqlCmd"
queries=$(curl --silent -X POST $KSQL_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQL_BASIC_AUTH_USER_INFO \
       -d @<(cat <<EOF
{
  "ksql": "$ksqlCmd",
  "streamsProperties": {}
}
EOF
) | jq -r '.[0].queries[].id')
for q in $queries; do
  ksqlCmd="TERMINATE $q;"
  echo -e "\n$ksqlCmd"
  curl -X POST $KSQL_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQL_BASIC_AUTH_USER_INFO \
       -d @<(cat <<EOF
{
  "ksql": "$ksqlCmd",
  "streamsProperties": {}
}
EOF
)
done
# Terminate streams and tables
while read ksqlCmd; do
  echo -e "\n$ksqlCmd"
  curl -X POST $KSQL_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQL_BASIC_AUTH_USER_INFO \
       -d @<(cat <<EOF
{
  "ksql": "$ksqlCmd",
  "streamsProperties": {}
}
EOF
)
done <cleanup_statements.sql

# Delete subjects from Confluent Cloud Schema Registry
schema_registry_subjects_to_delete="users-value pageviews-value"
for subject in $schema_registry_subjects_to_delete
do
  curl -X DELETE --silent -u $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL/subjects/$subject
done

# Delete topics in Confluent Cloud
topics_to_delete="pageviews users PAGEVIEWS_FEMALE PAGEVIEWS_REGIONS PAGEVIEWS_FEMALE_LIKE_89 USERS_ORIGINAL"
for topic in $topics_to_delete
do
  ccloud kafka topic describe $topic > /dev/null 2>&1 && ccloud kafka topic delete $topic 
done

