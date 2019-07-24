#!/bin/bash

# Source library 
. ../utils/helper.sh

CONFIG_FILE=~/.ccloud/config
check_ccloud_config $CONFIG_FILE || exit

./ccloud-generate-cp-configs.sh $CONFIG_FILE
source delta_configs/env.delta

check_env || exit 1

topics=$(kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --command-config delta_configs/ak-tools-ccloud.delta --list)

for topic in $topics
do
  if [[ ${topic:0:10} == '_confluent' ]]; then
    echo "Deleting $topic"
    kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --command-config delta_configs/ak-tools-ccloud.delta -delete --topic $topic 2>/dev/null
  fi
done

topics_to_delete="_schemas connect-configs connect-status connect-statuses connect-offsets"
for topic in $topics_to_delete
do
  if [[ $(kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --command-config delta_configs/ak-tools-ccloud.delta --describe --topic $topic 2>/dev/null) =~ "Topic:${topic}"$'\t' ]]; then
    echo "Deleting $topic"
    kafka-topics --bootstrap-server $BOOTSTRAP_SERVERS --command-config delta_configs/ak-tools-ccloud.delta -delete --topic $topic 2>/dev/null
  fi
done
