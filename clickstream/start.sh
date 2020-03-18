#!/bin/bash

# Source library
. ../utils/helper.sh

./stop.sh

docker-compose up -d
echo -e "\nSleeping 60 seconds while demo starts\n"
sleep 60

docker-compose exec ksql-cli bash -c "ksql http://ksql-server:8088 <<EOF
run script '/usr/share/doc/clickstream/clickstream-schema.sql';
exit ;
EOF"

docker-compose exec elasticsearch bash -c '/scripts/elastic-dynamic-template.sh'
docker-compose exec kafka-connect bash -c '/scripts/ksql-tables-to-grafana.sh'
docker-compose exec grafana bash -c '/scripts/clickstream-analysis-dashboard.sh'

echo -e "\n-> Navigate to the Grafana dashboard at http://localhost:3000/dashboard/db/click-stream-analysis.\n\nLogin with user ID admin and password admin.\n\n"
