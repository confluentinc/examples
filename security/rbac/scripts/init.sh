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
rm -rf /tmp/rbac_logs || true
rm -rf /tmp/original_configs || true
rm -rf /tmp/rbac_configs || true
rm -rf /tmp/zookeeper || true
rm -rf /tmp/kafka-logs || true
rm -rf /tmp/control-center || true
rm -f /tmp/login.properties || true
rm -f /tmp/tokenKeypair.pem || true
rm -f /tmp/tokenPublicKey.pem || true

mkdir -p /tmp/rbac_logs
mkdir -p /tmp/original_configs
mkdir -p /tmp/rbac_configs

./create_login_properties.py

# Generate keys
#
# MDS requires that the keypair be in PKCS#1 format, which as of OpenSSL 3.0.0 requires the -traditional flag. Passing
# this flag to earlier versions of OpenSSL throws an error so we only pass it for OpenSSL 3.0.0 and later. See MDS
# keypair requirements here: https://docs.confluent.io/platform/current/kafka/configure-mds/index.html#create-a-pem-key-pair
OPENSSL_VERSION=get_version_openssl
if version_gte $OPENSSL_VERSION "3.0.0" ; then
  OPENSSL_FLAGS="-traditional"
fi
openssl genrsa -out /tmp/tokenKeypair.pem $OPENSSL_FLAGS 2048
openssl rsa -in /tmp/tokenKeypair.pem -outform PEM -pubout -out /tmp/tokenPublicKey.pem

source ../config/local-demo.env

./stop-cp-services.sh
