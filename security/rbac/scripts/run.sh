#!/bin/bash

# Source library
. ../../../utils/helper.sh

export PATH="/Users/yeva/code/bin:$PATH"
check_env || exit 1
check_cli_v2 || exit 1
check_jq || exit 1

./init.sh

./broker.sh
./schema-registry.sh

./cleanup.sh
