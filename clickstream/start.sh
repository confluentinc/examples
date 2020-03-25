#!/bin/bash

# Source library
. ../utils/helper.sh

./stop.sh

# Get jars for source and sink connectors
docker run -v $PWD/confluent-hub-components:/share/confluent-hub-components confluentinc/ksqldb-server:0.8.0 confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:0.3.0
docker run -v $PWD/confluent-hub-components:/share/confluent-hub-components confluentinc/ksqldb-server:0.8.0 confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:5.4.1

docker-compose up -d
echo -e "\nSleeping 60 seconds while demo starts\n"
sleep 60

# Run the source connectors (with ksqlDB CLI) that generate data
docker-compose exec ksql-cli bash -c "ksql http://ksqldb-server:8088 <<EOF
run script '/scripts/create-connectors.sql';
exit ;
EOF"

echo -e "\nSleeping 30 seconds\n"
sleep 30

# Run the KSQL queries
docker-compose exec ksql-cli bash -c "ksql http://ksqldb-server:8088 <<EOF
run script '/scripts/clickstream-schema.sql';
exit ;
EOF"

echo -e "\nSleeping 10 seconds\n"
sleep 10

# Run the sink connector (with ksqlDB REST API) and setup Elasticsearch and Grafana
docker-compose exec ksqldb-server bash -c '/scripts/ksql-tables-to-grafana.sh'
docker-compose exec elasticsearch bash -c '/scripts/elastic-dynamic-template.sh'
docker-compose exec grafana bash -c '/scripts/clickstream-analysis-dashboard.sh'

cat <<EOF
Navigate to:
- Grafana dashboard (username/password is admin/admin):
      http://localhost:3000
- Confluent Control Center:
      http://localhost:9021
EOF
