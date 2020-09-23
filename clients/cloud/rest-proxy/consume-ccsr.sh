#!/bin/bash
  
# Create a consumer for Avro data, starting at the beginning of the topic's log
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     --data '{"name": "ci2", "format": "avro", "auto.offset.reset": "earliest"}' \
     http://localhost:8082/consumers/cg2 | jq .

# Subscribe to a topic
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     --data '{"topics":["test2"]}' \
     http://localhost:8082/consumers/cg2/instances/ci2/subscription | jq .

# Consume some data using the base URL in the first response.
# Note: Issue this command twice due to https://github.com/confluentinc/kafka-rest/issues/432
docker-compose exec rest-proxy curl -X GET \
     -H "Accept: application/vnd.kafka.avro.v2+json" \
     http://localhost:8082/consumers/cg2/instances/ci2/records | jq .

sleep 10

docker-compose exec rest-proxy curl -X GET \
     -H "Accept: application/vnd.kafka.avro.v2+json" \
     http://localhost:8082/consumers/cg2/instances/ci2/records | jq .

# Close the consumer with a DELETE to make it leave the group and clean up its resources
docker-compose exec rest-proxy curl -X DELETE \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     http://localhost:8082/consumers/cg2/instances/ci2 | jq .
