#!/bin/bash

set -eu

source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh

CONFIG_FILE=$HOME/.confluent/java.config
ccloud::validate_ccloud_config $CONFIG_FILE || exit

# Set topic name
topic_name=test1

# Create topic in Confluent Cloud
kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $CONFIG_FILE | tail -1` --command-config $CONFIG_FILE --topic $topic_name --create --replication-factor 3 --partitions 6

# To specify the configuration file for connecting to the Confluent Cloud cluster
#  option 1: use `-F <path>` argument (shown in the code below)
#  option 2: export `KAFKACAT_CONFIG`
#export KAFKACAT_CONFIG=$CONFIG_FILE

# Produce messages
num_messages=10
(for i in `seq 1 $num_messages`; do echo "alice,{\"count\":${i}}" ; done) | \
   kafkacat -F $HOME/.confluent/config \
            -K , \
            -P -t $topic_name

# Consume messages
kafkacat -F $HOME/.confluent/config \
         -K , \
         -C -t $topic_name -e
