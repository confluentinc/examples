#!/bin/bash

set -eu

source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh

CONFIG_FILE=$HOME/.confluent/librdkafka.config
ccloud::validate_ccloud_config $CONFIG_FILE || exit

# Set topic name
topic_name=test1

# Create topic in Confluent Cloud
confluent kafka topic create --if-not-exists $topic_name
# Uncomment below if local Kafka cluster
#kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $CONFIG_FILE | tail -1` --topic $topic_name --create --if-not-exists

# To specify the configuration file for connecting to the Confluent Cloud cluster
#  option 1: use `-F <path>` argument (shown in the code below)
#  option 2: export `KCAT_CONFIG`
#export KCAT_CONFIG=$CONFIG_FILE

# Produce messages
num_messages=10
(for i in `seq 1 $num_messages`; do echo "alice,{\"count\":${i}}" ; done) | \
   kcat -F $CONFIG_FILE \
        -K , \
        -P -t $topic_name

# Consume messages
kcat -F $CONFIG_FILE \
     -K , \
     -C -t $topic_name -e
