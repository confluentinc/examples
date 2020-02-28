#!/bin/bash

# Source library
. ../../../utils/helper.sh

CONFIG_FILE=$HOME/.confluent/java.config
check_ccloud_config $CONFIG_FILE || exit

../../../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE
source ./delta_configs/env.delta

./delete-topics.sh

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

