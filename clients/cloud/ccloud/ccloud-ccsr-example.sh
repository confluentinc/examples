#!/bin/bash

source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh 

check_timeout \
  && print_pass "timeout installed" \
  || exit 1
ccloud::validate_version_ccloud_cli $CCLOUD_MIN_VERSION \
  && print_pass "ccloud version ok" \
  || exit 1
ccloud::validate_logged_in_ccloud_cli \
  && print_pass "logged into ccloud CLI" \
  || exit 1

if [[ -z "$SR_API_KEY" ]] || [[ -z "$SR_API_SECRET" ]] ; then
  echo "ERROR: The variables SR_API_KEY and SR_API_SECRET must be set before running this script ('export SR_API_KEY=<>', 'export SR_API_SECRET=<>')"
  exit 1
fi

# Set topic name
topic_name=test2

# Create topic in Confluent Cloud
echo -e "\n# Create topic $topic_name"
ccloud kafka topic create $topic_name --if-not-exists

# Run producer to set credentials to Confluent Cloud Schema Registry (first time)
echo -e "\n# Set credentials to Confluent Cloud Schema Registry (first time)"
echo -e "${SR_API_KEY}\n${SR_API_SECRET}" | ccloud schema-registry subject list || exit 1

# Produce messages
echo -e "\n# Produce messages to $topic_name"
num_messages=10
(for i in `seq 1 $num_messages`; do echo "alice,{\"count\":${i}}" ; done) | \
   ccloud kafka topic produce $topic_name \
            --value-format avro \
            --schema schema.json \
            --parse-key \
            --delimiter ,

# Consume messages
echo -e "\n# Consume messages from $topic_name"
timeout 10 ccloud kafka topic consume $topic_name -b --value-format avro --print-key
