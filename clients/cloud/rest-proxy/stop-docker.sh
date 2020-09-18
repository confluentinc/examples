#!/bin/bash

# Source library
source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh

CONFIG_FILE=$HOME/.confluent/java.config
ccloud::validate_ccloud_config $CONFIG_FILE || exit

../../../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE
source ./delta_configs/env.delta

docker-compose down -v
