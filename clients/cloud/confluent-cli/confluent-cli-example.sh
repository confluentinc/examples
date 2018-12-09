#!/bin/bash

set -eu

# Set topic name
topic_name=test1

# Create topic in Confluent Cloud
ccloud topic create $topic_name || true

# Produce messages
num_messages=10
(for ((i=0;i<$num_messages;i++)); do echo "alice,{\"count\":${i}}" ; done) | \
   confluent produce $topic_name --cloud \
                                 --property parse.key=true \
                                 --property key.separator=,

# Consume messages
confluent consume $topic_name --cloud \
                              --property print.key=true \
                              --from-beginning
