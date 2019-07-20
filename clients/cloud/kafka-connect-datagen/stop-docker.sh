#!/bin/bash

# Source library
. ../../../utils/helper.sh

../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.ccloud/config
source ./delta_configs/env.delta

topics_to_delete="test1 test2 connect-configs connect-status connect-statuses connect-offsets"
for topic in $topics_to_delete
do
  if [[ $(docker-compose exec connect kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --command-config /tmp/ak-tools-ccloud.delta --describe --topic $topic) =~ "Topic:${topic}"$'\t' ]]; then
    echo "Deleting $topic"
    docker-compose exec connect kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --command-config /tmp/ak-tools-ccloud.delta -delete --topic $topic 2>/dev/null
  fi
done

docker-compose down

for v in $(docker volume ls -q --filter="dangling=true"); do
        docker volume rm "$v"
done

# Delete subjects from Confluent Cloud Schema Registry
schema_registry_subjects_to_delete="test2-value"
for subject in $schema_registry_subjects_to_delete
do
  curl -X DELETE --silent -u $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL/subjects/$subject
done

