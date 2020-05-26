#!/bin/bash

#########################################
# This script uses real Confluent Cloud resources.
# To avoid unexpected charges, carefully evaluate the cost of resources before launching the script and ensure all resources are destroyed after you are done running it.
#########################################

NAME=`basename "$0"`

# Source library
source ../utils/helper.sh

check_jq \
  && print_pass "jq found"

check_ccloud_version 1.0.0 \
  && print_pass "ccloud version ok"

check_ccloud_logged_in \
  && print_pass "logged into ccloud CLI" 

print_pass "Prerequisite check pass"

[[ -z "$AUTO" ]] && {
  printf "\n====== Confirm\n\n"
  prompt_continue_cloud_demo || exit 1
  read -p "Do you acknowledge this script creates a Confluent Cloud KSQL app (hourly charges may apply)? [y/n] " -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1; fi
	printf "\n"
} 

printf "\nFor your reference the demo will highlight some commands in "; print_code "code format"

printf "\n====== Starting\n\n"

wget -q -O docker-compose.yml https://raw.githubusercontent.com/confluentinc/cp-all-in-one/${CONFLUENT_RELEASE_TAG_OR_BRANCH}/cp-all-in-one-cloud/docker-compose.yml \
  && print_pass "retrieved docker-compose.yml from https://github.com/confluentinc/cp-all-in-one/cp-all-in-one-cloud/docker-compose.yml" \
  || exit_with_error -c $? -n "$NAME" -m "could not obtain cp-all-in-one docker-compose.yml" -l $(($LINENO -2))

printf "\n====== Creating new Confluent Cloud stack using the cloud_create_demo_stack function\nSee: %s for details\n" "https://github.com/confluentinc/examples/blob/$CONFLUENT_RELEASE_TAG_OR_BRANCH/utils/helper_cloud.sh"
cloud_create_demo_stack true  \
	&& print_code_pass -c "ccloud_create_demo_stack true"

SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name | split("-")[3]')
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
export CONFIG_FILE=$CONFIG_FILE
check_ccloud_config $CONFIG_FILE || exit 1

../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE \
	&& print_code_pass -c "../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE"

DELTA_CONFIGS=delta_configs/env.delta
printf "\nSetting local environment based on values in $DELTA_CONFIGS\n"
CMD="source $DELTA_CONFIGS"
eval $CMD \
    && print_code_pass -c "source $DELTA_CONFIGS" \
    || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3))

# Pre-flight check of Confluent Cloud credentials specified in $CONFIG_FILE
MAX_WAIT=720
printf "\n";print_process_start "Waiting up to $MAX_WAIT seconds for Confluent Cloud KSQL cluster to be UP"
retry $MAX_WAIT check_ccloud_ksql_endpoint_ready $KSQL_ENDPOINT || exit 1
print_pass "Confluent Cloud KSQL is UP"

ccloud_demo_preflight_check $CLOUD_KEY $CONFIG_FILE || exit 1

printf "\n";print_process_start "====== Pre-creating topics"

CMD="ccloud kafka topic create _confluent-monitoring"
$CMD \
  && print_code_pass -c "$CMD" \
  || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3))

CMD="ccloud kafka topic create pageviews"
$CMD \
  && print_code_pass -c "$CMD" \
  || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3)) 

CMD="ccloud kafka topic create users"
$CMD \
  && print_code_pass -c "$CMD" \
  || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3))

print_pass "Topics created"
 
printf "\n====== Starting local connect cluster in Docker to generate simulated data\n"
docker-compose up -d connect \
  && print_code_pass -c "docker-compose up -d connect" \
  || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -2))

# Verify Kafka Connect worker has started
MAX_WAIT=120
printf "\n"
print_process_start "Waiting up to $MAX_WAIT seconds for Kafka Connect to start"
retry $MAX_WAIT check_connect_up connect || exit 1
sleep 2 # give connect an exta moment to fully mature
print_pass "Kafka Connect has started"
 
printf "\n";print_process_start "====== Starting kafka-connect-datagen connectors to produce sample data."
printf "\tSee https://www.confluent.io/hub/confluentinc/kafka-connect-datagen for more information\n"
source ./connectors/submit_datagen_pageviews_config_cloud.sh
source ./connectors/submit_datagen_users_config_cloud.sh 
printf "\nSleeping 30 seconds to give kafka-connect-datagen a chance to start producing messages\n"
sleep 30

printf "\n====== Setting up ksqlDB\n"

printf "Obtaining the ksqlDB App Id\n"
CMD="ccloud ksql app list -o json | jq -r '.[].id'"
ksqlAppId=$(eval $CMD) \
  && print_code_pass -c "$CMD" -m "$ksqlAppId" \
  || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3))

printf "\nConfiguring ksqlDB ACLs\n"
CMD="ccloud ksql app configure-acls $ksqlAppId pageviews users PAGEVIEWS_FEMALE pageviews_female_like_89"
$CMD \
  && print_code_pass -c "$CMD" \
  || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3))

sleep 60
printf "\nSubmitting KSQL queries via curl to the ksqlDB REST endpoint\n"
printf "\tSee https://docs.ksqldb.io/en/latest/developer-guide/api/ for more information\n"
while read ksqlCmd; do # from docker-cloud-statements.sql
	response=$(curl -w "\n%{http_code}" -X POST $KSQL_ENDPOINT/ksql \
	       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
	       -u $KSQL_BASIC_AUTH_USER_INFO \
	       --silent \
	       -d @<(cat <<EOF
	{
	  "ksql": "$ksqlCmd",
	  "streamsProperties": {
			"ksql.streams.auto.offset.reset":"earliest",
			"ksql.streams.cache.max.bytes.buffering":"0"
		}
	}
EOF
	))
	echo "$response" | {
	  read body
	  read code
	  if [[ "$code" -gt 299 ]];
	    then print_code_error -c "$ksqlCmd" -m "$(echo "$body" | jq .message)"
	    else print_code_pass  -c "$ksqlCmd" -m "$(echo "$body" | jq -r .[].commandStatus.message)"
	  fi
	}
sleep 3;
done < docker-cloud-statements.sql
printf "\nksqlDB ready\n"

printf "\nLocal client configuration file written to $CONFIG_FILE\n\n"

printf "====== Verify\n"

printf "\nHere are some sample commands you can run to view data streaming in Avro and Protobuf format with the Kafka console commands.\n"

printf "\nTo view the Protobuf formatted data in the users topic:\n\t";print_code "docker run -it --rm --mount type=bind,source="$(pwd)"/delta_configs/ak-tools-ccloud.delta,target=/opt/docker/ak-tools-ccloud.delta cnfldemos/cp-server-connect-datagen:$KAFKA_CONNECT_DATAGEN_DOCKER_TAG kafka-protobuf-console-consumer --consumer.config /opt/docker/ak-tools-ccloud.delta --bootstrap-server $BOOTSTRAP_SERVERS --property schema.registry.url=$SCHEMA_REGISTRY_URL --property schema.registry.basic.auth.user.info=$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property basic.auth.credentials.source=USER_INFO --topic users"

printf "\nTo view the Avro formatted data in the pageviews topic:\n\t";print_code "docker run -it --rm --mount type=bind,source="$(pwd)"/delta_configs/ak-tools-ccloud.delta,target=/opt/docker/ak-tools-ccloud.delta cnfldemos/cp-server-connect-datagen:$KAFKA_CONNECT_DATAGEN_DOCKER_TAG kafka-avro-console-consumer --consumer.config /opt/docker/ak-tools-ccloud.delta --bootstrap-server $BOOTSTRAP_SERVERS --property schema.registry.url=$SCHEMA_REGISTRY_URL --property schema.registry.basic.auth.user.info=$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property basic.auth.credentials.source=USER_INFO --topic pageviews"

printf "\nConfluent Cloud KSQL is running and accruing charges. To destroy this demo, run and verify ->\n"
printf "\t./stop-docker-cloud.sh $CONFIG_FILE\n"

