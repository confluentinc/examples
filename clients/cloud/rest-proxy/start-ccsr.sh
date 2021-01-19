#!/bin/bash

source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh

CONFIG_FILE="${CONFIG_FILE:-$HOME/.confluent/java.config}"

ccloud::generate_configs $CONFIG_FILE || exit
source ./delta_configs/env.delta

wget -O docker-compose.yml https://raw.githubusercontent.com/confluentinc/cp-all-in-one/${CONFLUENT_RELEASE_TAG_OR_BRANCH}/cp-all-in-one-cloud/docker-compose.yml
./stop.sh
docker-compose up -d rest-proxy

# Verify REST Proxy has started
MAX_WAIT=60
echo "Waiting up to $MAX_WAIT seconds for REST Proxy to start"
retry $MAX_WAIT check_rest_proxy_up rest-proxy || exit 1
echo "REST Proxy has started!"

./produce-ccsr.sh
./consume-ccsr.sh
