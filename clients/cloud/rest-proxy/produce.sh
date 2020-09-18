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
topic_name=test1

# List clusters (using API v3 admin functionality)
docker-compose exec rest-proxy curl -X GET \
     -H "Content-Type: application/vnd.api+json" \
     -H "Accept: application/vnd.api+json" \
     -u "$CLOUD_KEY:$CLOUD_SECRET" \
     "http://localhost:8082/v3/clusters/"

# Create topic (using API v3 admin functionality)
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/json" \
     -H "accept: application/json" \
     -d "{\"topic_name\":\"$topic_name\",\"partitions_count\":6,\"replication_factor\":3,\"configs\":[{\"name\":\"cleanup.policy\",\"value\":\"compact\"}]}" \
     "http://localhost:8082/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" | jq

# Produce a message using JSON with the value '{ "foo": "bar" }'
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.json.v2+json" \
     -H "Accept: application/vnd.kafka.v2+json" \
     --data '{"records":[{"value":{"foo":"bar"}}]}' "http://localhost:8082/topics/$topic_name"
