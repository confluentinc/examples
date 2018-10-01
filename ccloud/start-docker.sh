#!/bin/bash

# Source library
. ../utils/helper.sh

check_ccloud || exit

./ccloud-generate-cp-configs.sh

source delta_configs/env.delta

ccloud topic create users
ccloud topic create pageviews

docker-compose up -d

echo "Sleeping 60 seconds to wait for all services to come up"
sleep 50

#curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{\"schema\": $(curl -s http://localhost:8085/subjects/pageviews-value/versions/latest | jq '.schema')}" http://localhost:8085/subjects/pageviews.replica-value/versions 

./submit_replicator_config.sh

sleep 10

docker-compose exec ksql-cli  bash -c "ksql http://ksql-server:8089 <<EOF
run script '/tmp/ksql.commands';
exit ;
EOF
"
