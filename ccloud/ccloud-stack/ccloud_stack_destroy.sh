#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
echo "DIR: $DIR"

# Source library
. $DIR/../../utils/helper.sh

check_ccloud_version 1.0.0 || exit 1
check_jq || exit 1
check_ccloud_logged_in || exit 1

if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './ccloud_stack_create.sh'. (Is it in stack-configs/ folder?) "
  exit 1
else
  CONFIG_FILE=$1
fi

read -p "This script with destroy the entire environment specified in $CONFIG_FILE.  Do you wish to proceed? [y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  exit 1
fi

check_ccloud_config $CONFIG_FILE || exit 1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
echo "DIR: $DIR"
$DIR/../ccloud-generate-cp-configs.sh $CONFIG_FILE > /dev/null
source delta_configs/env.delta
SERVICE_ACCOUNT_ID=$(ccloud_cli_get_service_account $CLOUD_KEY $CONFIG_FILE) || exit 1

echo
echo "Destroying..."
cloud_delete_demo_stack $SERVICE_ACCOUNT_ID

echo
echo "Tip: 'ccloud' CLI currently has no environment set"
