#!/bin/bash

#########################################
# This script uses real Confluent Cloud resources.
# To avoid unexpected charges, carefully evaluate the cost of resources before launching the script and ensure all resources are destroyed after you are done running it.
#########################################


# Source library
. ../../utils/helper.sh

check_ccloud_version 1.0.0 || exit 1
check_jq || exit 1
check_ccloud_logged_in || exit 1

prompt_continue_cloud_demo || exit 1

enable_ksql=false
read -p "Do you also want to create a Confluent Cloud KSQL app (hourly charges may apply)? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  enable_ksql=true
fi

echo
echo "Spin up..."
cloud_create_demo_stack $enable_ksql

echo
echo "Validating..."
SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
CONFIG_FILE=/tmp/client-$SERVICE_ACCOUNT_ID.config
check_ccloud_config $CONFIG_FILE || exit 1
../ccloud-generate-cp-configs.sh $CONFIG_FILE > /dev/null
source delta_configs/env.delta

if $enable_ksql ; then
  MAX_WAIT=720
  echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud KSQL cluster to be UP"
  retry $MAX_WAIT check_ccloud_ksql_endpoint_ready $KSQL_ENDPOINT || exit 1
fi

ccloud_demo_preflight_check $CLOUD_KEY $CONFIG_FILE $enable_ksql || exit 1

echo
echo "Local configuration file at $CONFIG_FILE:"
cat $CONFIG_FILE
echo

echo
echo "To spin down this Confluent Cloud stack run ->"
echo "    ./ccloud_stack_spin_down.sh $CONFIG_FILE"
echo
