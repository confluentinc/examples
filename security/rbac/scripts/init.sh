#!/bin/bash


# Source library
source ../../../utils/helper.sh

check_env || exit 1
validate_version_confluent_cli_v2 || exit 1
check_jq || exit 1

##################################################
# Initialize
##################################################

mkdir -p /tmp/original_configs
mkdir -p /tmp/rbac_configs

./create_login_properties.py

# Generate keys
openssl genrsa -out /tmp/tokenKeypair.pem 2048 
openssl rsa -in /tmp/tokenKeypair.pem -outform PEM -pubout -out /tmp/tokenPublicKey.pem

source ../config/local-demo.env

confluent local destroy
