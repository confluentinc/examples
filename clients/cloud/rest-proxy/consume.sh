#!/bin/bash
  
# Create a consumer for JSON data, starting at the beginning of the topic's log
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     --data '{"name": "ci1", "format": "json", "auto.offset.reset": "earliest"}' \
     http://localhost:8082/consumers/cg1 | jq .

# Subscribe to a topic
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     --data '{"topics":["test1"]}' \
     http://localhost:8082/consumers/cg1/instances/ci1/subscription | jq .

# Consume some data using the base URL in the first response.
# Note: Issue this command twice due to https://github.com/confluentinc/kafka-rest/issues/432
docker-compose exec rest-proxy curl -X GET \
     -H "Accept: application/vnd.kafka.json.v2+json" \
     http://localhost:8082/consumers/cg1/instances/ci1/records | jq .

sleep 10

docker-compose exec rest-proxy curl -X GET \
     -H "Accept: application/vnd.kafka.json.v2+json" \
     http://localhost:8082/consumers/cg1/instances/ci1/records | jq .

# Close the consumer with a DELETE to make it leave the group and clean up its resources
docker-compose exec rest-proxy curl -X DELETE \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     http://localhost:8082/consumers/cg1/instances/ci1 | jq .
