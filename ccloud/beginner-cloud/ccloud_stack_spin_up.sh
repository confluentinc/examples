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

RANDOM_NUM=$((1 + RANDOM % 1000000))

echo "Spin up..."
cloud_create_demo_stack $RANDOM_NUM

echo "Validating..."
CONFIG_FILE=/tmp/client-$RANDOM_NUM.config
check_ccloud_config $CONFIG_FILE || exit 1
../ccloud-generate-cp-configs.sh $CONFIG_FILE > /dev/null
source delta_configs/env.delta

MAX_WAIT=720
echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud KSQL cluster to be UP"
retry $MAX_WAIT check_ccloud_ksql_endpoint_ready $KSQL_ENDPOINT || exit 1

ccloud_demo_preflight_check $CLOUD_KEY $CONFIG_FILE || exit 1

echo
echo "To spin down this stack, run './ccloud_stack_spin_down.sh $RANDOM_NUM'"
echo
