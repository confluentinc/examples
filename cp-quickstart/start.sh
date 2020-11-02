#!/bin/bash

# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

check_env \
  && print_pass "Confluent Platform installed" \
  || exit 1
check_running_cp ${CONFLUENT} \
  && print_pass "Confluent Platform version ${CONFLUENT} ok" \
  || exit 1
validate_version_confluent_cli_for_cp \
  && print_pass "Confluent CLI version ok" \
  || exit 1
sleep 1

./stop.sh

confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:$KAFKA_CONNECT_DATAGEN_VERSION
confluent local services start
sleep 10

if check_cp; then
  confluent local services connect connector config datagen-pageviews --config connectors/datagen_pageviews.config
  confluent local services connect connector config datagen-users --config connectors/datagen_users.config
else
  confluent local services connect connector config datagen-pageviews --config connectors/datagen_pageviews_oss.config
  confluent local services connect connector config datagen-users --config connectors/datagen_users_oss.config
fi
sleep 20

confluent local services connect connector status

ksql http://localhost:8088 <<EOF
run script 'statements.sql';
exit ;
EOF
