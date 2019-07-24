#!/bin/bash

# Source library 
. ../utils/helper.sh

check_env || exit 1

. ./config.sh
check_ccloud_config $CONFIG_FILE || exit

DELTA_CONFIGS_DIR="delta_configs"
./ccloud-generate-cp-configs.sh $CONFIG_FILE
source delta_configs/env.delta

# Kill processes
confluent local destroy
jps | grep DataGen | awk '{print $1;}' | xargs kill -9
jps | grep KsqlServerMain | awk '{print $1;}' | xargs kill -9
jps | grep SchemaRegistry | awk '{print $1;}' | xargs kill -9
jps | grep ReplicatorApp | awk '{print $1;}' | xargs kill -9
jps | grep ControlCenter | awk '{print $1;}' | xargs kill -9
jps | grep ConnectDistributed | awk '{print $1;}' | xargs kill -9

# Delete subjects from Confluent Cloud Schema Registry
if [[ "${USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY}" == true ]]; then
  schema_registry_subjects_to_delete="users-value pageviews-value"
  for subject in $schema_registry_subjects_to_delete
  do
    curl -X DELETE --silent -u $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL/subjects/$subject
  done
fi

# Delete topics in Confluent Cloud
topics=$(kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $CONFIG_FILE | tail -1` --command-config $CONFIG_FILE --list)
topics_to_delete="pageviews pageviews.replica users pageviews_enriched_r8_r9 PAGEVIEWS_FEMALE PAGEVIEWS_REGIONS PAGEVIEWS_FEMALE_LIKE_89"
for topic in $topics_to_delete
do
  echo $topics | grep $topic &>/dev/null
  if [[ $? == 0 ]]; then
    kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $CONFIG_FILE | tail -1` --command-config $CONFIG_FILE --delete --topic $topic
  fi
done

#./ccloud-delete-all-topics.sh
