#!/bin/bash

NAME=`basename "$0"`
# Setting default QUIET=false to surface potential errors
QUIET="${QUIET:-false}"
[[ $QUIET == "true" ]] && 
  REDIRECT_TO="/dev/null" ||
  REDIRECT_TO="/dev/tty"

# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

check_jq \
  && print_pass "jq found"

[[ -z "$AUTO" ]] && {
  printf "\n====== Confirm\n\n"
  ccloud::prompt_continue_ccloud_demo || exit 1
} 

ccloud::validate_version_cli $CLI_MIN_VERSION \
  && print_pass "Confluent CLI version ok"

ccloud::validate_logged_in_cli \
  && print_pass "Logged into the Confluent CLI" 

print_pass "Prerequisite check pass"

printf "\n====== Starting\n\n"

printf "\n====== Creating new Confluent Cloud stack using the ccloud::create_ccloud_stack function\nSee: %s for details\n" "https://github.com/confluentinc/examples/blob/$CONFLUENT_RELEASE_TAG_OR_BRANCH/utils/ccloud_library.sh"
export EXAMPLE="ccloud-observability"
ccloud::create_ccloud_stack false  \
	&& print_code_pass -c "ccloud::create_ccloud_stack false"

SERVICE_ACCOUNT_ID=$(ccloud:get_service_account_from_current_cluster_name)
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
export CONFIG_FILE=$CONFIG_FILE
ccloud::validate_ccloud_config $CONFIG_FILE || exit 1

ccloud::generate_configs $CONFIG_FILE \
	&& print_code_pass -c "ccloud::generate_configs $CONFIG_FILE"

DELTA_CONFIGS_ENV=delta_configs/env.delta
printf "\nSetting local environment based on values in $DELTA_CONFIGS_ENV\n"
CMD="source $DELTA_CONFIGS_ENV"
eval $CMD \
    && print_code_pass -c "source $DELTA_CONFIGS_ENV" \
    || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3))

##################################################
# Start up monitoring
##################################################
echo -e "\n====== Create cloud api-key and set environment variables for the ccloud-exporter"
echo "confluent api-key create --resource cloud --description \"confluent-cloud-metrics-api\" -o json"
OUTPUT=$(confluent api-key create --resource cloud --description "confluent-cloud-metrics-api" -o json)
rm .env 2>/dev/null
echo "$OUTPUT" | jq .
export METRICS_API_KEY=$(echo "$OUTPUT" | jq -r ".key")
export METRICS_API_SECRET=$(echo "$OUTPUT" | jq -r ".secret")
export CLOUD_CLUSTER=$CLUSTER

echo -e "\n====== Starting up Prometheus, Grafana, exporters, and clients"
echo "docker-compose up -d"
docker-compose up -d
echo -e "\n====== Login to grafana at http://localhost:3000/ un:admin pw:password"
echo -e "\n====== Query metrics in prometheus at http://localhost:9090 (verify targets are being scraped at http://localhost:9090/targets/, may take a few minutes to start up)"

echo "CONFIG_FILE=$CONFIG_FILE" >> .env
echo "SERVICE_ACCOUNT_ID=$SERVICE_ACCOUNT_ID" >> .env
echo "METRICS_API_KEY=$METRICS_API_KEY" >> .env
echo "METRICS_API_SECRET=$METRICS_API_SECRET" >> .env
echo "CLOUD_CLUSTER=$CLOUD_CLUSTER" >> .env
echo "BOOTSTRAP_SERVERS=$BOOTSTRAP_SERVERS" >> .env
echo "SASL_JAAS_CONFIG=$SASL_JAAS_CONFIG" >> .env

echo
echo "Confluent Cloud Environment:"
echo
echo "  export CONFIG_FILE=$CONFIG_FILE"
echo "  export SERVICE_ACCOUNT_ID=$SERVICE_ACCOUNT_ID"
echo "  export METRICS_API_KEY=$METRICS_API_KEY"
echo "  export METRICS_API_SECRET=$METRICS_API_SECRET"
echo "  export CLOUD_CLUSTER=$CLOUD_CLUSTER"
echo "  export BOOTSTRAP_SERVERS=$BOOTSTRAP_SERVERS"
echo "  export SASL_JAAS_CONFIG=$SASL_JAAS_CONFIG"
