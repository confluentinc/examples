#!/bin/bash

CONFIG_FILE=$HOME/.confluent/java.config

source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh

check_env || exit
validate_version_confluent_cli_v2 || exit
ccloud::validate_ccloud_config $CONFIG_FILE || exit

set -eu

ccloud::generate_configs $CONFIG_FILE
source delta_configs/env.delta

# Set topic name
topic_name=test2

# Create topic in Confluent Cloud
echo -e "\n# Create topic $topic_name"
kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $CONFIG_FILE | tail -1` --command-config $CONFIG_FILE --topic $topic_name --create --replication-factor 3 --partitions 6 2>/dev/null || true

# Produce messages
echo -e "\n# Produce messages to $topic_name"
num_messages=10
(for i in `seq 1 $num_messages`; do echo "{\"count\":${i}}" ; done) | \
   confluent local services kafka produce $topic_name \
                                       --cloud \
                                       --config $CONFIG_FILE \
                                       --value-format avro \
                                       --property value.schema='{"type":"record","name":"myrecord","fields":[{"name":"count","type":"int"}]}' \
                                       --property basic.auth.credentials.source=${BASIC_AUTH_CREDENTIALS_SOURCE} \
                                       --property schema.registry.basic.auth.user.info=${SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO} \
                                       --property schema.registry.url=${SCHEMA_REGISTRY_URL} 2>/dev/null

# Consume messages
echo -e "\n# Consume messages from $topic_name"
confluent local services kafka consume $topic_name \
                                    --cloud \
                                    --config $CONFIG_FILE \
                                    --value-format avro \
                                    --property basic.auth.credentials.source=${BASIC_AUTH_CREDENTIALS_SOURCE} \
                                    --property schema.registry.basic.auth.user.info=${SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO} \
                                    --property schema.registry.url=${SCHEMA_REGISTRY_URL} \
                                    --from-beginning \
                                    --timeout-ms 10000 2>/dev/null
