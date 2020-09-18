#!/bin/bash
  
source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh

CONFIG_FILE="${CONFIG_FILE:-$HOME/.confluent/java.config}"
ccloud::validate_ccloud_config $CONFIG_FILE || exit

./stop-docker.sh

../../../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE || exit
source ./delta_configs/env.delta

docker-compose up -d

# Verify REST Proxy has started
MAX_WAIT=60
echo "Waiting up to $MAX_WAIT seconds for REST Proxy to start"
retry $MAX_WAIT check_rest_proxy_up rest-proxy || exit 1
echo "REST Proxy has started!"

# Set topic name
topic_name=${topic_name:-test1}

# List clusters (API v3)
KAFKA_CLUSTER_ID=$(docker-compose exec rest-proxy curl -X GET \
     "http://localhost:8082/v3/clusters/" | jq -r ".data[0].cluster_id")
echo "KAFKA_CLUSTER_ID: $KAFKA_CLUSTER_ID"

# Create topic (API v3)
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/json" \
     -d "{\"topic_name\":\"$topic_name\",\"partitions_count\":6,\"replication_factor\":3,\"configs\":[]}" \
     "http://localhost:8082/v3/clusters/${KAFKA_CLUSTER_ID}/topics"
