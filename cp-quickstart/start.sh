#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 5.3 || exit

./stop.sh

confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:latest
confluent local start
sleep 10

if is_ce; then
  ./connectors/submit_datagen_pageviews_config.sh
  ./connectors/submit_datagen_users_config.sh
else
  ./connectors/submit_datagen_pageviews_config_oss.sh
  ./connectors/submit_datagen_users_config_oss.sh
fi
sleep 20

ksql http://localhost:8088 <<EOF
run script 'ksql.commands';
exit ;
EOF
