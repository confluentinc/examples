#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 5.0 || exit 

./stop.sh

get_ksql_ui
confluent start

if is_ce; then PROPERTIES=" propertiesFile=$CONFLUENT_HOME/etc/ksql/datagen.properties"; else PROPERTIES=""; fi
ksql-datagen quickstart=pageviews format=delimited topic=pageviews maxInterval=100 $PROPERTIES &>/dev/null &
ksql-datagen quickstart=users format=json topic=users maxInterval=1000 $PROPERTIES &>/dev/null &
sleep 5

ksql http://localhost:8088 <<EOF
run script 'ksql.commands';
exit ;
EOF
