#!/bin/bash

source ./delta_configs/env.delta

topics_to_delete="test1 test2"
for topic in $topics_to_delete
do
  if [[ $(docker-compose exec connect kafka-topics --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --command-config /tmp/ak-tools-ccloud.delta --describe --topic $topic) =~ "Topic:${topic}"$'\t' ]]; then
    echo "Deleting $topic"
    docker-compose exec connect kafka-topics --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --command-config /tmp/ak-tools-ccloud.delta -delete --topic $topic 2>/dev/null
  fi
done
