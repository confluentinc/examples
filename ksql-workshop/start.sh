#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 5.1 || exit 

./stop.sh

echo "auto.offset.reset=earliest" >> $CONFLUENT_HOME/etc/ksql/ksql-server.properties
confluent start

cat data/customers.json | kafka-console-producer --broker-list localhost:9092 --topic customers

if is_ce; then PROPERTIES=" propertiesFile=$CONFLUENT_HOME/etc/ksql/datagen.properties"; else PROPERTIES=""; fi
ksql-datagen quickstart=ratings format=avro topic=ratings maxInterval=500 schemaRegistryUrl=http://localhost:8081 $PROPERTIES &>/dev/null &
sleep 5

ksql http://localhost:8088 <<EOF
run script 'ksql.commands';
exit ;
EOF
