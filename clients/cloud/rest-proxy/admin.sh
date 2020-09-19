#!/bin/bash
  
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
