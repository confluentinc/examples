#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_mvn || exit 1
check_running_cp ${CP_VERSION_FULL} || exit 

./stop.sh

echo "auto.offset.reset=earliest" >> $CONFLUENT_HOME/etc/ksqldb/ksql-server.properties
confluent local start

get_and_compile_kafka_streams_examples || exit 1
java -cp kafka-streams-examples/target/kafka-streams-examples-${CONFLUENT}-standalone.jar io.confluent.examples.streams.interactivequeries.kafkamusic.KafkaMusicExampleDriver &>/dev/null &

sleep 5

ksql http://localhost:8088 <<EOF
run script 'statements.sql';
exit ;
EOF
