#!/bin/bash

# Source library
source ../utils/helper.sh

wget -O docker-compose.yml https://raw.githubusercontent.com/confluentinc/cp-all-in-one/${CONFLUENT_RELEASE_TAG_OR_BRANCH}/cp-all-in-one-kraft/docker-compose.yml
wget -O update_run.sh https://raw.githubusercontent.com/confluentinc/cp-all-in-one/${CONFLUENT_RELEASE_TAG_OR_BRANCH}/cp-all-in-one-kraft/update_run.sh
chmod 744 update_run.sh

./stop-docker.sh

docker-compose up -d

# Verify Kafka Connect worker has started
MAX_WAIT=120
echo "Waiting up to $MAX_WAIT seconds for Connect to start"
retry $MAX_WAIT check_connect_up connect || exit 1
sleep 2 # give connect an exta moment to fully mature
echo "connect has started!"

# Configure datagen connectors
source ./connectors/submit_datagen_pageviews_config.sh
source ./connectors/submit_datagen_users_config.sh

# Verify topics exist
MAX_WAIT=30
echo -e "\nWaiting up to $MAX_WAIT seconds for topics (pageviews, users) to exist"
retry $MAX_WAIT check_topic_exists broker broker:29092 pageviews || exit 1
retry $MAX_WAIT check_topic_exists broker broker:29092 users || exit 1
echo "Topics exist!"

# Read topics
docker-compose exec connect kafka-avro-console-consumer --bootstrap-server broker:29092 --timeout-ms 10000 --max-messages 5 --topic users --property schema.registry.url=http://schema-registry:8081
docker-compose exec connect kafka-avro-console-consumer --bootstrap-server broker:29092 --timeout-ms 10000 --max-messages 5 --topic pageviews --property schema.registry.url=http://schema-registry:8081

printf "\n====== Successfully Completed ======\n\n"
