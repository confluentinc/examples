#!/bin/bash

# Source library
. ../../../utils/helper.sh

CONFIG_FILE=~/.ccloud/config
check_ccloud_config $CONFIG_FILE || exit

../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.ccloud/config
source ./delta_configs/env.delta

topics_to_delete="test1 test2"
topics=$(docker-compose exec connect bash -c 'kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" /tmp/ak-tools-ccloud.delta | tail -1` --command-config /tmp/ak-tools-ccloud.delta --list 2>/dev/null')
for topic in $topics_to_delete
do
  echo $topics | grep $topic &>/dev/null
  if [[ $? == 0 ]]; then
    docker-compose exec connect bash -c 'kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" /tmp/ak-tools-ccloud.delta | tail -1` --command-config /tmp/ak-tools-ccloud.delta --topic $topic --delete'
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

