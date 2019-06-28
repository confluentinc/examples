#!/bin/bash

set -eu

../../../ccloud/ccloud-generate-cp-configs.sh
source delta_configs/env.delta

# Set topic name
topic_name=test2

# Create topic in Confluent Cloud
ccloud topic create $topic_name || true

# Produce messages
num_messages=10
(for i in `seq 1 $num_messages`; do echo "{\"count\":${i}}" ; done) | \
   confluent local produce $topic_name -- \
                                       --cloud \
                                       --value-format avro \
                                       --property value.schema='{"type":"record","name":"myrecord","fields":[{"name":"count","type":"int"}]}' \
                                       --property basic.auth.credentials.source=${BASIC_AUTH_CREDENTIALS_SOURCE} \
                                       --property schema.registry.basic.auth.user.info=${SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO} \
                                       --property schema.registry.url=${SCHEMA_REGISTRY_URL}

# Consume messages
confluent local consume $topic_name -- \
                                    --cloud \
                                    --value-format avro \
                                    --property basic.auth.credentials.source=${BASIC_AUTH_CREDENTIALS_SOURCE} \
                                    --property schema.registry.basic.auth.user.info=${SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO} \
                                    --property schema.registry.url=${SCHEMA_REGISTRY_URL} \
                                    --from-beginning
