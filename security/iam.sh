#!/bin/bash


################################################################################
# Overview
################################################################################
#
# Demo the new Confluent CLI and Identiy Access Management (IAM) functionality
#
# Documentation accompanying this tutorial:
#
#   <>
#
# DISCLAIMER:
#
#   This is mostly for reference to see a workflow using Confluent CLI
#
#   If you choose to run it against your Kafka cluster, be aware that it:
#      - is for demo purposes only
#      - should be used only on a non-production cluster
#
# Usage:
#
#   # Provide all arguments on command line
#   ./iam.sh <url to metadata server> <username> <password>
#
#   # Provide all arguments on command line, except password for which you will be prompted
#   ./iam.sh <url to metadata server> <username>
#
# Requirements:
#
#   - Local install of the new Confluent CLI (v0.96.0 or above)
#
################################################################################

# Source library
. ../utils/helper.sh

export PATH="/Users/yeva/code/bin:$PATH"
check_cli_v2 || exit 1


##################################################
# Read URL, USERNAME, PASSWORD from command line arguments
#
#  Rudimentary argument processing and must be in order:
#    <url to metadata server> <username> <password>
##################################################
URL=$1
USERNAME=$2
PASSWORD=$3
if [[ -z "$URL" ]]; then
  read -s -p "Metadata Server (MDS): " URL
  echo ""
fi
if [[ -z "$USERNAME" ]]; then
  read -s -p "Username: " USERNAME
  echo ""
fi
if [[ -z "$PASSWORD" ]]; then
  read -s -p "Password: " PASSWORD
  echo ""
fi


##################################################
# Log in, specify active cluster, and create a user key/secret 
##################################################

echo -e "\n# Login"
OUTPUT=$(
expect <<END
  log_user 1
  spawn confluent login --url $URL
  expect "Username: "
  send "$USERNAME\r";
  expect "Password: "
  send "$PASSWORD\r";
  expect "Logged in as "
  set result $expect_out(buffer)
END
)
echo "$OUTPUT"
if [[ ! "$OUTPUT" =~ "Logged in as" ]]; then
  echo "Failed to log into your cluster.  Please check all parameters and run again"
  exit 1
fi


##################################################
# Cleanup
#
##################################################

echo -e "\n# Cleanup"
