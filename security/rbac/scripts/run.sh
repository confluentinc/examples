#!/bin/bash

################################################################################
# Overview
################################################################################
#
# Demo the Role Based Access Control (RBAC) functionality with the new Confluent CLI
#
# Usage:
#
#   ./run.sh
#
# Requirements:
#
#   - Local install of Confluent CLI (v0.265.0 or above)
#
################################################################################

# Source library
source ../../../utils/helper.sh

check_env \
  && print_pass "Confluent Platform installed" \
  || exit 1
check_running_cp ${CONFLUENT} \
  && print_pass "Confluent Platform version ${CONFLUENT} ok" \
  || exit 1
validate_version_confluent_cli_for_cp \
  && print_pass "Confluent CLI version ok" \
  || exit 1
check_jq \
  && print_pass "jq installed" \
  || exit 1
sleep 1


./cleanup.sh
./init.sh

./enable-rbac-broker.sh
./enable-rbac-schema-registry.sh
./enable-rbac-connect.sh
./enable-rbac-rest-proxy.sh
./enable-rbac-ksqldb-server.sh
./enable-rbac-control-center.sh

#./cleanup.sh
