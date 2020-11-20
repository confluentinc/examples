#!/bin/bash

TOPICS_FILE="$@"
BOOTSTRAP_SERVERS=${BOOTSTRAP_SERVERS:-"broker:9092"}
PARTITIONS=${PARTITIONS:-1}
REPLICATION_FACTOR=${REPLICATION_FACTOR:-1}

CURRENT_TOPICS=$(ccloud kafka topic list -o json)

while IFS= read -r TOPIC; 
  do
    [[ -z "$TOPIC" ]] || {
      TOPIC_EXISTS=$(jq "map(select(.name == \"$TOPIC\")) | length" <<< "$CURRENT_TOPICS")
      if [ $TOPIC_EXISTS -eq 1 ]; then 
        printf "topic $TOPIC already exists\n"
      else
        printf "\nCreating topic $TOPIC on Confluent Cloud\n"
        ccloud kafka topic create $TOPIC
      fi
    }
  done <$TOPICS_FILE

