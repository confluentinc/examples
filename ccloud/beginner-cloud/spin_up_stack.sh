#!/bin/bash


# Source library
. ../../utils/helper.sh
. ../../utils/cloud_stack.sh

check_ccloud_version 1.0.0 || exit 1
check_timeout || exit 1
check_mvn || exit 1
check_expect || exit 1
check_jq || exit 1
check_docker || exit 1
check_ccloud_logged_in || exit 1


RANDOM_NUM=$((1 + RANDOM % 1000000))

echo "Spin up:"
cloud_create_demo_stack $RANDOM_NUM

echo "Spin down:"
cloud_delete_demo_stack $RANDOM_NUM
