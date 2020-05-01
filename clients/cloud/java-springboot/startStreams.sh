#!/bin/bash

RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'

# including some common utilities (`check_ccloud_config`, `validate_confluent_cloud_schema_registry`, etc)
. ../../../utils/helper.sh

echo -e "\n${BLUE}\t☁️  Generating a config from Confluent Cloud properties... ${NC}\n"

export CONFIG_FILE=~/.ccloud/java.config
check_ccloud_config $CONFIG_FILE || exit

SCHEMA_REGISTRY_CONFIG_FILE=$HOME/.ccloud/config

../../../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE $SCHEMA_REGISTRY_CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

validate_confluent_cloud_schema_registry $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO $SCHEMA_REGISTRY_URL || exit 1


echo -e "${GREEN}\t🍃  Starting Spring Boot application (Kafka Streams)... ${NC}"

java -cp build/libs/java-springboot-0.0.1-SNAPSHOT.jar -Dloader.main=io.confluent.examples.clients.cloud.springboot.streams.SpringbootStreamsApplication org.springframework.boot.loader.PropertiesLauncher 
