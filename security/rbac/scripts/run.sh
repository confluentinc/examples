#!/bin/bash

################################################################################
# Overview
################################################################################
#
# Demo the Role Based Access Control (RBAC) functionality with the new Confluent CLI
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
#   ./run.sh
#
# Requirements:
#
#   - Local install of the new Confluent CLI (v0.96.0 or above)
#
################################################################################

# Source library
. ../../../utils/helper.sh

check_env || exit 1
check_cli_v2 || exit 1
check_jq || exit 1


./init.sh

./enable-rbac-broker.sh
./enable-rbac-schema-registry.sh
./enable-rbac-connect.sh
./enable-rbac-ksql-server.sh

#./cleanup.sh
