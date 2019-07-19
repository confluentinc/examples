#!/bin/bash

set -eu

# Set topic name
topic_name=test1

# Create topic in Confluent Cloud
kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" ~/.ccloud/config | tail -1` --command-config ~/.ccloud/config --topic $topic_name --create --replication-factor 3 --partitions 6

# Produce messages
num_messages=10
(for i in `seq 1 $num_messages`; do echo "alice,{\"count\":${i}}" ; done) | \
   confluent local produce $topic_name -- \
                                       --cloud \
                                       --property parse.key=true \
                                       --property key.separator=,

# Consume messages
confluent local consume $topic_name -- \
                                    --cloud \
                                    --property print.key=true \
                                    --from-beginning
