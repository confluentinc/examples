#!/bin/bash


# Source library
source ../../../utils/helper.sh

check_env || exit 1
validate_version_confluent_cli_v2 || exit 1
check_jq || exit 1

##################################################
# Initialize
##################################################

# remove any logs / configs from previous runs for which users didn't run cleanup.sh
rm -f /tmp/rbac_logs || true
rm -f /tmp/original_configs || true
rm -f /tmp/rbac_configs || true
rm -f /tmp/control-center || true

mkdir -p /tmp/rbac_logs
mkdir -p /tmp/original_configs
mkdir -p /tmp/rbac_configs

./create_login_properties.py

# Generate keys
openssl genrsa -out /tmp/tokenKeypair.pem 2048 
openssl rsa -in /tmp/tokenKeypair.pem -outform PEM -pubout -out /tmp/tokenPublicKey.pem

source ../config/local-demo.env

./stop-cp-services.sh
