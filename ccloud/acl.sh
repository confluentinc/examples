#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_jq || exit 1
check_running_cp 5.1 || exit 1
check_ccloud || exit 1
check_ccloud_v2 || exit 1

# Read CLUSTER, EMAIL, PASSWORD
CLUSTER=$1
EMAIL=$2
if [[ -z "$1" ]]; then
  read -s -p "Cloud cluster: " CLUSTER
  echo ""
fi
if [[ -z "$2" ]]; then
  read -s -p "Cloud user email: " EMAIL
  echo ""
fi
read -s -p "Cloud user password: " PASSWORD

# 1. Init user
## 1a. Login
output=$(
expect <<END
  log_user 1
  spawn ccloud login --url $CLUSTER
  expect "Email: "
  send "$EMAIL\r";
  expect "Password: "
  send "$PASSWORD\r";
  expect "Logged in as "
  set result $expect_out(buffer)
END
)
echo "$output"
if [[ ! "$output" =~ "Logged in as" ]]; then
  echo "Failed to log into your cluster.  Please check all parameters and run again"
  exit 1
fi



# use context
# auth
# Basic produce/consume
# Create topic1
# CLI Product/consume from topic
# Produce with basic ACL
# Create service account
# Create API keys for service account
# Try to run produce client (it should fail)
# Create WRITE ACLs and produce client should pass
# Consume with wildcard ACL
# Try to run consume client (it should fail)
# Create READ ACL with wildcard on topic and consume client should pass
# Consume with prefixed ACL
# Create topic2
# Try to run produce client (it should fail)
# Create WRITE ACL with prefix on topic (specifically `--prefix`) and produce client should pass
