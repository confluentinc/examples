#!/bin/bash


# Source library
. ../../utils/helper.sh

check_ccloud_version 1.0.0 || exit 1
check_jq || exit 1
check_ccloud_logged_in || exit 1

if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the RANDOM_NUM value output from running './ccloud_stack_spin_up.sh'"
  exit 1
else
  RANDOM_NUM=$1
fi

echo
echo "Spin down..."
cloud_delete_demo_stack $RANDOM_NUM
