#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 5.1 || exit 

./stop.sh

confluent start

if is_ce; then PROPERTIES=" propertiesFile=$CONFLUENT_HOME/etc/ksql/datagen.properties"; else PROPERTIES=""; fi
ksql-datagen quickstart=pageviews format=avro topic=pageviews maxInterval=100 schemaRegistryUrl=http://localhost:8081 $PROPERTIES &>/dev/null &
ksql-datagen quickstart=users format=avro topic=users maxInterval=1000 schemaRegistryUrl=http://localhost:8081 $PROPERTIES &>/dev/null &
sleep 5

ksql http://localhost:8088 <<EOF
run script 'ksql.commands';
exit ;
EOF
