#!/bin/bash

source ../../../utils/ccloud_library.sh

CONFIG_FILE="${CONFIG_FILE:-$HOME/.confluent/java.config}"

ccloud::generate_configs $CONFIG_FILE || exit
source ./delta_configs/env.delta
  
# List clusters (API v3)
KAFKA_CLUSTER_ID=$(docker-compose exec rest-proxy curl -X GET \
     "http://localhost:8082/v3/clusters/" | jq -r ".data[0].cluster_id")

# Create topic (API v3)
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/json" \
     -d "{\"topic_name\":\"test2\",\"partitions_count\":6,\"configs\":[]}" \
     "http://localhost:8082/v3/clusters/${KAFKA_CLUSTER_ID}/topics" | jq .

# Register a new Avro schema for topic test2
docker-compose exec rest-proxy curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{ "schema": "[ { \"type\":\"record\", \"name\":\"countInfo\", \"fields\": [ {\"name\":\"count\",\"type\":\"long\"}]} ]" }' -u "$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO" "$SCHEMA_REGISTRY_URL/subjects/test2-value/versions"

# Get the Avro schema id
schemaid=$(docker-compose exec rest-proxy curl -X GET -u "$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO" "$SCHEMA_REGISTRY_URL/subjects/test2-value/versions/latest" | jq '.id')

# Produce an Avro message (API v2)
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.avro.v2+json" \
     -H "Accept: application/vnd.kafka.v2+json" \
     --data '{"value_schema_id": '"$schemaid"', "records": [{"value": {"countInfo":{"count": 0}}},{"value": {"countInfo":{"count": 1}}},{"value": {"countInfo":{"count": 2}}}]}' \
     "http://localhost:8082/topics/test2" | jq .
