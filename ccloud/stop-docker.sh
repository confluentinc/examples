#!/bin/bash

# Source library
. ../utils/helper.sh

. ./config.sh
check_ccloud_config $CONFIG_FILE || exit

./ccloud-generate-cp-configs.sh $CONFIG_FILE
source delta_configs/env.delta

topics_to_delete="pageviews pageviews.replica users pageviews_enriched_r8_r9 PAGEVIEWS_FEMALE PAGEVIEWS_REGIONS"
for topic in $topics_to_delete
do
  if [[ $(docker-compose exec connect-cloud kafka-topics --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --command-config /tmp/ak-tools-ccloud.delta --describe --topic $topic) =~ "Topic:${topic}"$'\t' ]]; then
    echo "Deleting $topic"
    docker-compose exec connect-cloud kafka-topics --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --command-config /tmp/ak-tools-ccloud.delta -delete --topic $topic 2>/dev/null
  fi
done

docker-compose down

for v in $(docker volume ls -q --filter="dangling=true"); do
        docker volume rm "$v"
done

# Delete subjects from Confluent Cloud Schema Registry
if [[ "${USE_CONFLUENT_CLOUD_SCHEMA_REGISTRY}" == true ]]; then
  schema_registry_subjects_to_delete="users-value pageviews-value"
  for subject in $schema_registry_subjects_to_delete
  do
    curl -X DELETE --silent -u $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL/subjects/$subject
  done
fi
