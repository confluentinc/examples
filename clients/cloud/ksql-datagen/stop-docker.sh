#!/bin/bash

# Source library
source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh

CONFIG_FILE="${CONFIG_FILE:-$HOME/.confluent/java.config}"
ccloud::validate_ccloud_config $CONFIG_FILE || exit

ccloud::generate_configs $CONFIG_FILE
source ./delta_configs/env.delta

./delete-topics.sh

docker-compose down -v

# Delete subjects from Confluent Cloud Schema Registry
schema_registry_subjects_to_delete="test2-value"
for subject in $schema_registry_subjects_to_delete
do
  curl -X DELETE --silent -u $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL/subjects/$subject
done

