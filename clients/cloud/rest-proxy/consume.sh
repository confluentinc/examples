#!/bin/bash
  
CONFIG_FILE=$HOME/.confluent/java.config

source ../../../utils/helper.sh

# Set topic name
topic_name=test3

# Create a consumer for JSON data, starting at the beginning of the topic's log
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     --data '{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}' \
     http://localhost:8082/consumers/my_json_consumer

# Subscribe to a topic
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     --data '{"topics":["$topic_name"]}' \
     http://localhost:8082/consumers/my_json_consumer/instances/my_consumer_instance/subscription

# Consume some data using the base URL in the first response.
docker-compose exec rest-proxy curl -X GET \
     -H "Accept: application/vnd.kafka.json.v2+json" \
     http://localhost:8082/consumers/my_json_consumer/instances/my_consumer_instance/records

# Close the consumer with a DELETE to make it leave the group and clean up its resources.
docker-compose exec rest-proxy curl -X DELETE \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     http://localhost:8082/consumers/my_json_consumer/instances/my_consumer_instance
