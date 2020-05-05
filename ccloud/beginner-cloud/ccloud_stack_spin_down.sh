#!/bin/bash


# Source library
. ../../utils/helper.sh

check_ccloud_version 1.0.0 || exit 1
check_jq || exit 1
check_ccloud_logged_in || exit 1

if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './ccloud_stack_spin_up.sh'"
  exit 1
else
  CONFIG_FILE=$1
fi

check_ccloud_config $CONFIG_FILE || exit 1
../ccloud-generate-cp-configs.sh $CONFIG_FILE > /dev/null
source delta_configs/env.delta
SERVICE_ACCOUNT_ID=$(ccloud_cli_get_service_account $CLOUD_KEY $CONFIG_FILE) || exit 1
echo "SERVICE_ACCOUNT_ID: $SERVICE_ACCOUNT_ID"

echo
echo "Spin down..."
cloud_delete_demo_stack $SERVICE_ACCOUNT_ID
