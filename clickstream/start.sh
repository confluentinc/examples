#!/bin/bash

# Source library
source ../utils/helper.sh

./stop.sh

# Get jars for source and sink connectors
docker run -v $PWD/confluent-hub-components:/share/confluent-hub-components confluentinc/ksqldb-server:0.8.0 confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:$KAFKA_CONNECT_DATAGEN_VERSION
docker run -v $PWD/confluent-hub-components:/share/confluent-hub-components confluentinc/ksqldb-server:0.8.0 confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:$KAFKA_CONNECT_ES_VERSION

docker-compose up -d

MAX_WAIT=90
echo "Waiting up to $MAX_WAIT seconds for ksqlDB server's embedded Connect to be ready"
retry $MAX_WAIT check_connect_up ksqldb-server || exit 1

# Verify ksqlDB server has started
MAX_WAIT=30
echo "Waiting up to $MAX_WAIT seconds for ksqlDB server to be ready to serve requests"
retry $MAX_WAIT host_check_ksqlDBserver_up || exit 1

sleep 2

# Run the source connectors (with ksqlDB CLI) that generate data
docker-compose exec ksqldb-cli bash -c "ksql http://ksqldb-server:8088 <<EOF
run script '/scripts/create-connectors.sql';
exit ;
EOF"

echo -e "\nSleeping 30 seconds until ksqlDB server starts and topics have data\n"
sleep 30

# Run the KSQL queries
docker-compose exec ksqldb-cli bash -c "ksql http://ksqldb-server:8088 <<EOF
run script '/scripts/statements.sql';
exit ;
EOF"

echo -e "\nSleeping 10 seconds\n"
sleep 10

# Run the sink connector (with ksqlDB REST API) and setup Elasticsearch and Grafana
docker-compose exec elasticsearch bash -c '/scripts/elastic-dynamic-template.sh'
docker-compose exec ksqldb-server bash -c '/scripts/ksql-tables-to-grafana.sh'
docker-compose exec grafana bash -c '/scripts/clickstream-analysis-dashboard.sh'

cat <<EOF
Navigate to:
- Grafana dashboard (username/password is user/user):
      http://localhost:3000
- Confluent Control Center:
      http://localhost:9021
EOF

./sessionize-data.sh
