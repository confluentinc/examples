#!/bin/bash

# Source library
. ../utils/helper.sh

./ccloud-generate-cp-configs.sh
source delta_configs/env.delta

docker-compose down

for v in $(docker volume ls -q --filter="dangling=true"); do
        docker volume rm "$v"
done

# Delete subjects from Confluent Cloud Schema Registry
. ./config.sh
if [[ "${USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY}" == true ]]; then
  schema_registry_subjects_to_delete="users-value pageviews-value"
  for subject in $schema_registry_subjects_to_delete
  do
    curl -X DELETE --silent -u $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL/subjects/$subject
  done
fi

topics=$(kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" ~/.ccloud/config | tail -1` --command-config ~/.ccloud/config --list)

topics_to_delete="pageviews pageviews.replica users pageviews_enriched_r8_r9 PAGEVIEWS_FEMALE PAGEVIEWS_REGIONS"
for topic in $topics_to_delete
do
  echo $topics | grep $topic &>/dev/null
  if [[ $? == 0 ]]; then
    kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" ~/.ccloud/config | tail -1` --command-config ~/.ccloud/config --delete --topic $topic
  fi
done
