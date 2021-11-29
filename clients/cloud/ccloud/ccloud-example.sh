#!/bin/bash

source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh 

check_timeout \
  && print_pass "timeout installed" \
  || exit 1
ccloud::validate_version_cli $CLI_MIN_VERSION \
  && print_pass "Confluent CLI version ok" \
  || exit 1
ccloud::validate_logged_in_cli \
  && print_pass "Logged into the Confluent CLI" \
  || exit 1

# Set topic name
topic_name=test1

# Create topic in Confluent Cloud
echo -e "\n# Create topic $topic_name"
confluent kafka topic create $topic_name --if-not-exists

# Produce messages
echo -e "\n# Produce messages to $topic_name"
num_messages=10
(for i in `seq 1 $num_messages`; do echo "alice,{\"count\":${i}}" ; done) | \
   confluent kafka topic produce $topic_name \
           --parse-key \
           --delimiter ,

# Consume messages
echo -e "\n# Consume messages from $topic_name"
timeout 10 confluent kafka topic consume $topic_name -b --print-key
