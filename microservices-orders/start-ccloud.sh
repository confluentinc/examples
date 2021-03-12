#!/bin/bash

# Source library
source ../utils/ccloud_library.sh
source ../utils/helper.sh

MAX_WAIT=${MAX_WAIT:-60}

ccloud::validate_version_ccloud_cli $CCLOUD_MIN_VERSION \
  && print_pass "ccloud version ok"

ccloud::validate_logged_in_ccloud_cli \
  && print_pass "logged into ccloud CLI"

printf "\n====== Create new Confluent Cloud stack\n"
[[ -z "$NO_PROMPT" ]] && ccloud::prompt_continue_ccloud_demo
export EXAMPLE="microservices-orders"
ccloud::create_ccloud_stack true

SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
if [[ "$SERVICE_ACCOUNT_ID" == "" ]]; then
  printf "\nERROR: Could not determine SERVICE_ACCOUNT_ID from 'ccloud kafka cluster list'. Please troubleshoot, destroy stack, and try again to create the stack.\n"
  exit 1
fi
export CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config

printf "\n====== Generating Confluent Cloud configurations\n"
ccloud::generate_configs $CONFIG_FILE

DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

printf "\n====== Creating demo topics\n"
./scripts/create-topics-ccloud.sh ./topics.txt

printf "\n====== Starting local services in Docker\n"
docker-compose up -d --build 

printf "\n====== Giving services $WARMUP_TIME seconds to startup\n"
sleep $WARMUP_TIME 
MAX_WAIT=240
echo "Waiting up to $MAX_WAIT seconds for connect to start"
retry $MAX_WAIT check_connect_up connect || exit 1
printf "\n\n"

printf "\n====== Configuring Elasticsearch mappings\n"
./dashboard/set_elasticsearch_mapping.sh

printf "\n====== Submitting connectors\n\n"
printf "====== Submitting Kafka Connector to source customers from sqlite3 database and produce to topic 'customers'\n"
INPUT_FILE=./connectors/connector_jdbc_customers_template.config 
OUTPUT_FILE=./connectors/rendered-connectors/connector_jdbc_customers.config 
SQLITE_DB_PATH=/opt/docker/db/data/microservices.db
source ./scripts/render-connector-config.sh 
curl -s -S -XPOST -H Accept:application/json -H Content-Type:application/json http://localhost:8083/connectors/ -d @$OUTPUT_FILE

printf "\n\n====== Submitting Kafka Connector to sink records from 'orders' topic to Elasticsearch\n"
INPUT_FILE=./connectors/connector_elasticsearch_template.config
OUTPUT_FILE=./connectors/rendered-connectors/connector_elasticsearch.config 
ELASTICSEARCH_URL=http://elasticsearch:9200
source ./scripts/render-connector-config.sh
curl -s -S -XPOST -H Accept:application/json -H Content-Type:application/json http://localhost:8083/connectors/ -d @$OUTPUT_FILE

printf "\n====== Validating and setting up ksqlDB App\n"

MAX_WAIT_KSQLDB=720
printf "\n====== Waiting up to $MAX_WAIT_KSQLDB for ksqlDB to be ready\n"
retry $MAX_WAIT_KSQLDB ccloud::validate_ccloud_ksqldb_endpoint_ready $KSQLDB_ENDPOINT || exit 1

printf "====== Creating ksqlDB ACLs\n"
ccloud kafka acl create --allow --service-account $KSQLDB_SERVICE_ACCOUNT_ID --operation READ --topic 'orders'
printf "\n"
ccloud kafka acl create --allow --service-account $KSQLDB_SERVICE_ACCOUNT_ID --operation READ --topic 'customers'
printf "\n"

printf "\n====== Creating ksqlDB STREAMS and TABLES\n"
KQLDB_QUERY_PROPERTIES='"ksql.streams.auto.offset.reset":"earliest","ksql.streams.cache.max.bytes.buffering":"0"'
while read ksqlCmd; do
  printf "\n$ksqlCmd\n"
  response=$(curl -X POST $KSQLDB_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQLDB_BASIC_AUTH_USER_INFO \
       --silent \
       -d @<(cat <<EOF
{
  "ksql": "$ksqlCmd",
  "streamsProperties": {$properties}
}
EOF
))
  printf "\n$response\n"
  if [[ ! "$response" =~ "SUCCESS" ]]; then
		if [[ ! "$response" =~ "already exists" ]]; then
    	echo -e "\nERROR: KSQL command '$ksqlCmd' did not include \"SUCCESS\" in the response.  Please troubleshoot.\n"
    	exit 1
		fi
  fi
done <statements-ccloud.sql

printf "\n\n====== Configuring Kibana Dashboard\n"
./dashboard/configure_kibana_dashboard.sh

printf "\n\n====== Reading data from topics and ksqlDB\n"
CONFIG_FILE=/opt/docker/$CONFIG_FILE ./read-topics-ccloud.sh

echo
echo "To destroy the Confluent Cloud resources and stop the demo, run ->"
echo "    ./stop-ccloud.sh $CONFIG_FILE"
echo

echo
ENVIRONMENT=$(ccloud::get_environment_id_from_service_id $SERVICE_ACCOUNT_ID)
echo "Tip: 'ccloud' CLI has been set to the new environment $ENVIRONMENT"

