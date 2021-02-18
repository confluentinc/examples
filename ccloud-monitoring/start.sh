#!/bin/bash

NAME=`basename "$0"`
QUIET="${QUIET:-true}"
[[ $QUIET == "true" ]] && 
  REDIRECT_TO="/dev/null" ||
  REDIRECT_TO="/dev/stdout"

# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

check_jq \
  && print_pass "jq found"

ccloud::validate_version_ccloud_cli 1.7.0 \
  && print_pass "ccloud version ok"

ccloud::validate_logged_in_ccloud_cli \
  && print_pass "logged into ccloud CLI" 

print_pass "Prerequisite check pass"

[[ -z "$AUTO" ]] && {
  printf "\n====== Confirm\n\n"
  ccloud::prompt_continue_ccloud_demo || exit 1
} 

printf "\nFor your reference the demo will highlight some commands in "; print_code "code format"

printf "\n====== Starting\n\n"

printf "\n====== Creating new Confluent Cloud stack using the ccloud::create_ccloud_stack function\nSee: %s for details\n" "https://github.com/confluentinc/examples/blob/$CONFLUENT_RELEASE_TAG_OR_BRANCH/utils/ccloud_library.sh"
export EXAMPLE="ccloud-monitoring"
ccloud::create_ccloud_stack false  \
	&& print_code_pass -c "cccloud::create_ccloud_stack false"

SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name | split("-")[3]')
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

ccloud::validate_ccloud_stack_up $CLOUD_KEY $CONFIG_FILE || exit 1



##################################################
# Start up monitoring
##################################################
echo -e "\n# Create demo-topic-4"
ccloud kafka topic create demo-topic-4

echo -s "\n# Set all acls to do use cases"
ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation CREATE --topic demo-topic-4
ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation WRITE --topic demo-topic-4
ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation READ --topic demo-topic-4
ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation READ  --consumer-group demo-beginner-cloud-1

echo -e "\n# Create cloud api-key and add it to .env"
echo "ccloud api-key create --resource cloud --description \"ccloud-exporter\" -o json"
OUTPUT=$(ccloud api-key create --resource cloud --description "ccloud-exporter" -o json)
rm .env 2>/dev/null
echo "$OUTPUT" | jq .
echo "CCLOUD_API_KEY=$(echo "$OUTPUT" | jq -r ".key")">>.env
echo "CCLOUD_API_SECRET=$(echo "$OUTPUT" | jq -r ".secret")">>.env
echo "CCLOUD_CLUSTER=$CLUSTER">>.env
echo "Build client container"
docker build -t localbuild/client:latest .
echo -e "\n#Starting up Prometheus, Grafana, and exporters"
echo "docker-compose up -d"
docker-compose up -d
echo -e "\n#Login to grafana at http://localhost:3000/ un:admin pw:password"
echo -e "\n#Query metrics in prometheus at http://localhost:9090 (verify targets are being scraped at http://localhost:9090/targets/, may take a few minutes to start up)"
