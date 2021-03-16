#!/bin/bash
  
# List clusters (API v3)
KAFKA_CLUSTER_ID=$(docker-compose exec rest-proxy curl -X GET \
     "http://localhost:8082/v3/clusters/" | jq -r ".data[0].cluster_id")

# Create topic (API v3)
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/json" \
     -d "{\"topic_name\":\"test1\",\"partitions_count\":6,\"configs\":[]}" \
     "http://localhost:8082/v3/clusters/${KAFKA_CLUSTER_ID}/topics" | jq .

# Produce 3 messages using JSON (API v2)
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.json.v2+json" \
     -H "Accept: application/vnd.kafka.v2+json" \
     --data '{"records":[{"key":"alice","value":{"count":0}},{"key":"alice","value":{"count":1}},{"key":"alice","value":{"count":2}}]}' \
     "http://localhost:8082/topics/test1" | jq .
