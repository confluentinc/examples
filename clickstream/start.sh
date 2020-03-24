#!/bin/bash

# Source library
. ../utils/helper.sh

./stop.sh

docker-compose up -d
echo -e "\nSleeping 60 seconds while demo starts\n"
sleep 60

# Run the source connectors (with ksqlDB CLI) that generate data
docker-compose exec ksql-cli bash -c "ksql http://ksqldb-server:8088 <<EOF
run script '/scripts/create-connectors.sql';
exit ;
EOF"

sleep 5

# Run the KSQL queries
docker-compose exec ksql-cli bash -c "ksql http://ksqldb-server:8088 <<EOF
run script '/scripts/clickstream-schema.sql';
exit ;
EOF"

sleep 5

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
