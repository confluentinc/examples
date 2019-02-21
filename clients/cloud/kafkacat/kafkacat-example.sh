#!/bin/bash

set -eu

# Set topic name
topic_name=test3

# Create topic in Confluent Cloud
ccloud topic create $topic_name || true

# Produce messages
num_messages=10
(for i in `seq 0 $num_messages`; do echo "alice,{\"count\":${i}}" ; done) | \
   kafkacat -F $HOME/.ccloud/config \
            -K , \
            -P -t $topic_name

# Consume messages
kafkacat -F $HOME/.ccloud/config \
         -K , \
         -C -t $topic_name
