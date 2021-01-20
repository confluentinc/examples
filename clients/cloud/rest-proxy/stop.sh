#!/bin/bash

# Source library
source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh

CONFIG_FILE=$HOME/.confluent/java.config
ccloud::validate_ccloud_config $CONFIG_FILE || exit

ccloud::generate_configs $CONFIG_FILE
source ./delta_configs/env.delta

# List clusters (API v3)
KAFKA_CLUSTER_ID=$(docker-compose exec rest-proxy curl -X GET \
     "http://localhost:8082/v3/clusters/" | jq -r ".data[0].cluster_id")

# Delete topic (API v3)
docker-compose exec rest-proxy curl -X DELETE \
     "http://localhost:8082/v3/clusters/${KAFKA_CLUSTER_ID}/topics/test1"
docker-compose exec rest-proxy curl -X DELETE \
     "http://localhost:8082/v3/clusters/${KAFKA_CLUSTER_ID}/topics/test2"

docker-compose stop rest-proxy
docker-compose rm -f rest-proxy
