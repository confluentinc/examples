#!/bin/bash


################################################################################
# Overview
################################################################################
#
# Demo the Role Based Access Control (RBAC) and Identity Access Management (IAM) functionality
# with the new Confluent CLI
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
#   ./rbac.sh
#
# Requirements:
#
#   - Local install of the new Confluent CLI (v0.96.0 or above)
#
################################################################################

# Source library
. ../../../utils/helper.sh

export PATH="/Users/yeva/code/bin:$PATH"
check_env || exit 1
check_cli_v2 || exit 1
check_jq || exit 1

##################################################
# Initialize
##################################################

mkdir -p ../original_configs

# Copy login.properties
cp ../login.properties /tmp/login.properties

# Generate keys
openssl genrsa -out /tmp/tokenKeypair.pem 2048 
openssl rsa -in /tmp/tokenKeypair.pem -outform PEM -pubout -out /tmp/tokenPublicKey.pem

. ../config/local-demo.cfg

confluent local destroy
