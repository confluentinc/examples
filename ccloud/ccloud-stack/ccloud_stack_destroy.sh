#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Source library
source $DIR/../../utils/helper.sh
source $DIR/../../utils/ccloud_library.sh

ccloud::validate_version_ccloud_cli 1.7.0 || exit 1
ccloud::validate_logged_in_ccloud_cli || exit 1
check_jq || exit 1

if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './ccloud_stack_create.sh'. (Is it in stack-configs/ folder?) "
  exit 1
else
  CONFIG_FILE=$1
fi

read -p "This script will destroy the entire environment specified in $CONFIG_FILE.  Do you want to proceed? [y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  exit 1
fi

ccloud::validate_ccloud_config $CONFIG_FILE || exit 1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
$DIR/../ccloud-generate-cp-configs.sh $CONFIG_FILE > /dev/null
source delta_configs/env.delta
SERVICE_ACCOUNT_ID=$(ccloud::get_service_account $CLOUD_KEY $CONFIG_FILE) || exit 1

echo
ccloud::destroy_ccloud_stack $SERVICE_ACCOUNT_ID

echo
echo "Tip: 'ccloud' CLI currently has no environment set"
