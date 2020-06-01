#!/bin/bash

# Source library
source ../utils/helper.sh

wget -O docker-compose.yml https://raw.githubusercontent.com/confluentinc/cp-all-in-one/${CONFLUENT_RELEASE_TAG_OR_BRANCH}/cp-all-in-one-community/docker-compose.yml

./stop-docker.sh

docker-compose up -d

# Verify Kafka Connect worker has started
MAX_WAIT=120
echo "Waiting up to $MAX_WAIT seconds for Connect to start"
retry $MAX_WAIT check_connect_up connect || exit 1
sleep 2 # give connect an exta moment to fully mature
echo "connect has started!"

# Configure datagen connectors
wget -O connector_pageviews_cos.config  https://github.com/confluentinc/kafka-connect-datagen/raw/master/config/connector_pageviews_cos.config
curl -X POST -H "Content-Type: application/json" --data @connector_pageviews_cos.config http://localhost:8083/connectors
wget -O connector_users_cos.config https://github.com/confluentinc/kafka-connect-datagen/raw/master/config/connector_users_cos.config
curl -X POST -H "Content-Type: application/json" --data @connector_users_cos.config http://localhost:8083/connectors

# Verify topics exist
MAX_WAIT=30
echo -e "\nWaiting up to $MAX_WAIT seconds for topics (pageviews, users) to exist"
retry $MAX_WAIT check_topic_exists broker broker:9092 pageviews || exit 1
retry $MAX_WAIT check_topic_exists broker broker:9092 users || exit 1
echo "Topics exist!"

# Run the KSQL queries
docker-compose exec ksqldb-cli bash -c "ksql http://ksqldb-server:8088 <<EOF
run script '/tmp/statements.sql';
exit ;
EOF"
