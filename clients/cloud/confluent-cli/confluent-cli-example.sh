#!/bin/bash

CONFIG_FILE=$HOME/.confluent/java.config

source ../../../utils/helper.sh 
source ../../../utils/ccloud_library.sh 

check_env || exit
validate_version_confluent_cli_v2 || exit
ccloud::validate_ccloud_config $CONFIG_FILE || exit

set -eu

# Set topic name
topic_name=test1

# Create topic in Confluent Cloud
echo -e "\n# Create topic $topic_name"
kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $CONFIG_FILE | tail -1` --command-config $CONFIG_FILE --topic $topic_name --create 2>/dev/null || true

# Produce messages
echo -e "\n# Produce messages to $topic_name"
num_messages=10
(for i in `seq 1 $num_messages`; do echo "alice,{\"count\":${i}}" ; done) | \
   confluent local services kafka produce $topic_name \
                                       --cloud \
                                       --config $CONFIG_FILE \
                                       --property parse.key=true \
                                       --property key.separator=, 2>/dev/null

# Consume messages
echo -e "\n# Consume messages from $topic_name"
confluent local services kafka consume $topic_name \
                                    --cloud \
                                    --config $CONFIG_FILE \
                                    --property print.key=true \
                                    --from-beginning \
                                    --timeout-ms 10000 2>/dev/null
