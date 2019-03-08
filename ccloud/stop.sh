#!/bin/bash

# Source library 
. ../utils/helper.sh

check_env || exit 1
check_ccloud || exit

source delta_configs/env.delta

# Kill processes
confluent destroy
jps | grep DataGen | awk '{print $1;}' | xargs kill -9
jps | grep KsqlServerMain | awk '{print $1;}' | xargs kill -9
jps | grep SchemaRegistry | awk '{print $1;}' | xargs kill -9
jps | grep ReplicatorApp | awk '{print $1;}' | xargs kill -9
jps | grep ControlCenter | awk '{print $1;}' | xargs kill -9
jps | grep ConnectDistributed | awk '{print $1;}' | xargs kill -9

# Delete subjects from Confluent Schema Registry
#schema_registry_subjects_to_delete="users-value pageviews-value"
#for subject in $schema_registry_subjects_to_delete
#do
#  curl -X DELETE -u $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL/subjects/$subject
#done

# Delete topics in Confluent Cloud
topics=$(ccloud topic list)
topics_to_delete="pageviews pageviews.replica users pageviews_enriched_r8_r9 PAGEVIEWS_FEMALE PAGEVIEWS_REGIONS"
for topic in $topics_to_delete
do
  echo $topics | grep $topic &>/dev/null
  if [[ $? == 0 ]]; then
    ccloud topic delete $topic
  fi
done

#./ccloud-delete-all-topics.sh
