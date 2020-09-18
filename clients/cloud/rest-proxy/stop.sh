#!/bin/bash

# Source library
source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh

CONFIG_FILE=$HOME/.confluent/java.config
ccloud::validate_ccloud_config $CONFIG_FILE || exit

../../../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE
source ./delta_configs/env.delta

# Set topic name
topic_name=${topic_name:-test1}

# List clusters (API v3)
KAFKA_CLUSTER_ID=$(docker-compose exec rest-proxy curl -X GET \
     "http://localhost:8082/v3/clusters/" | jq -r ".data[0].cluster_id")

# Delete topic (API v3)
docker-compose exec rest-proxy curl -X DELETE \
     "http://localhost:8082/v3/clusters/${KAFKA_CLUSTER_ID}/topics/$topic_name"

docker-compose down -v
