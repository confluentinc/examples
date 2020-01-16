#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 5.4 || exit
check_cli_v2 || exit

./stop.sh

confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:0.2.0
confluent local start
sleep 10

if check_cp; then
  confluent local config datagen-pageviews -- -d connectors/datagen_pageviews.config
  confluent local config datagen-users -- -d connectors/datagen_users.config
else
  confluent local config datagen-pageviews -- -d connectors/datagen_pageviews_oss.config
  confluent local config datagen-users -- -d connectors/datagen_users_oss.config
fi
sleep 20

confluent local status connectors

ksql http://localhost:8088 <<EOF
run script 'ksql.commands';
exit ;
EOF
