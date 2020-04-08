#!/bin/bash

# Source library
. ../utils/helper.sh

wget -O docker-compose.yml https://raw.githubusercontent.com/confluentinc/cp-all-in-one/master/cp-all-in-one/docker-compose.yml

./stop-docker.sh

docker-compose up -d

# Verify Kafka Connect worker has started
MAX_WAIT=120
echo "Waiting up to $MAX_WAIT seconds for Connect to start"
retry $MAX_WAIT check_connect_up connect || exit 1
sleep 2 # give connect an exta moment to fully mature
echo "connect has started!"

. ./connectors/submit_datagen_pageviews_config.sh
. ./connectors/submit_datagen_users_config.sh

# Verify topics exist
MAX_WAIT=30
echo -e "\nWaiting up to $MAX_WAIT seconds for topics (pageviews, users) to exist"
retry $MAX_WAIT check_topic_exists broker broker:9092 pageviews || exit 1
retry $MAX_WAIT check_topic_exists broker broker:9092 users || exit 1
echo "Topics exist!"

# Run the KSQL queries
docker-compose exec ksql-cli bash -c "ksql http://ksqldb-server:8088 <<EOF
run script '/tmp/statements.sql';
exit ;
EOF"
