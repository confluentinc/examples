#!/bin/bash


# Source library
. ../../utils/helper.sh

check_ccloud_version 1.0.0 || exit 1
check_timeout || exit 1
check_mvn || exit 1
check_expect || exit 1
check_jq || exit 1
check_docker || exit 1
check_ccloud_logged_in || exit 1


RANDOM_NUM=$((1 + RANDOM % 1000000))

echo "Spin up..."
cloud_create_demo_stack $RANDOM_NUM

echo "Validating..."
CONFIG_FILE=/tmp/client-$RANDOM_NUM.config
check_ccloud_config $CONFIG_FILE || exit 1
./ccloud-generate-cp-configs.sh $CONFIG_FILE > /dev/null
source delta_configs/env.delta
ccloud_demo_preflight_check $CLOUD_KEY $CONFIG_FILE || exit 1

echo
echo
#echo "Spin down..."
#cloud_delete_demo_stack $RANDOM_NUM
