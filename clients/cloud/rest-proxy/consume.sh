#!/bin/bash
  
# Set topic name
topic_name=${topic_name:-test1}

cg_name=cg1
ci=ci1

# Create a consumer for JSON data, starting at the beginning of the topic's log
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     --data '{"name": "'"$ci"'", "format": "json", "auto.offset.reset": "earliest"}' \
     http://localhost:8082/consumers/$cg_name

# Subscribe to a topic
docker-compose exec rest-proxy curl -X POST \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     --data '{"topics":["'"$topic_name"'"]}' \
     http://localhost:8082/consumers/$cg_name/instances/$ci/subscription

# Consume some data using the base URL in the first response.
docker-compose exec rest-proxy curl -X GET \
     -H "Accept: application/vnd.kafka.json.v2+json" \
     http://localhost:8082/consumers/$cg_name/instances/$ci/records

# Consume some data using the base URL in the first response.
docker-compose exec rest-proxy curl -X GET \
     -H "Accept: application/vnd.kafka.json.v2+json" \
     http://localhost:8082/consumers/$cg_name/instances/$ci/records

# Close the consumer with a DELETE to make it leave the group and clean up its resources
docker-compose exec rest-proxy curl -X DELETE \
     -H "Content-Type: application/vnd.kafka.v2+json" \
     http://localhost:8082/consumers/$cg_name/instances/$ci
