#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_mvn || exit 1
check_running_cp 5.1 || exit 

./stop.sh

echo "auto.offset.reset=earliest" >> $CONFLUENT_HOME/etc/ksql/ksql-server.properties
confluent start

[[ -d "kafka-streams-examples" ]] || git clone https://github.com/confluentinc/kafka-streams-examples.git
(cd kafka-streams-examples && git checkout 5.1.0-post)
[[ -f "kafka-streams-examples/target/kafka-streams-examples-5.1.0-standalone.jar" ]] || (cd kafka-streams-examples && mvn clean package -DskipTests)
java -cp kafka-streams-examples/target/kafka-streams-examples-5.1.0-standalone.jar io.confluent.examples.streams.interactivequeries.kafkamusic.KafkaMusicExampleDriver &>/dev/null &

sleep 5

ksql http://localhost:8088 <<EOF
run script 'ksql.commands';
exit ;
EOF
