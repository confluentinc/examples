#!/bin/bash
  
# Set topic name
topic_name=${topic_name:-test1}

# List clusters (API v3)
KAFKA_CLUSTER_ID=$(docker-compose exec rest-proxy curl -X GET \
     "http://localhost:8082/v3/clusters/" | jq -r ".data[0].cluster_id")

# Produce a message using JSON with the value '{ "foo": "bar" }' (API v2)
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.json.v2+json" \
     -H "Accept: application/vnd.kafka.v2+json" \
     --data '{"records":[{"value":{"foo":"bar"}}]}' \
     "http://localhost:8082/topics/$topic_name"
