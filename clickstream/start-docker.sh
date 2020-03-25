#!/bin/bash

# Source library
. ../utils/helper.sh

docker-compose down
./stop.sh

docker-compose up -d
echo -e "\nSleeping 60 seconds while demo starts\n"
sleep 60

# Run the KSQL queries
docker-compose exec ksql-cli bash -c "ksql http://ksql-server:8088 <<EOF
RUN SCRIPT '/usr/share/doc/clickstream/clickstream-schema.sql';
exit ;
EOF"

echo -e "\nSleeping 10 seconds\n"
sleep 10

# Run the sink connector (with ksqlDB REST API) and setup Elasticsearch and Grafana
docker-compose exec elasticsearch bash -c '/scripts/elastic-dynamic-template.sh'
docker-compose exec kafka-connect bash -c '/scripts/ksql-tables-to-grafana.sh'
docker-compose exec grafana bash -c '/scripts/clickstream-analysis-dashboard.sh'

cat <<EOF
Navigate to:
- Grafana dashboard (username/password is user/user):
      http://localhost:3000
- Confluent Control Center:
      http://localhost:9021
EOF

