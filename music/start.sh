#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_mvn || exit 1
check_running_cp ${CP_VERSION_MAJOR} || exit 

./stop.sh

echo "auto.offset.reset=earliest" >> $CONFLUENT_HOME/etc/ksql/ksql-server.properties
confluent local start

[[ -d "kafka-streams-examples" ]] || git clone https://github.com/confluentinc/kafka-streams-examples.git
(cd kafka-streams-examples && git fetch && git pull && git checkout ${GH_BRANCH})
[[ -f "kafka-streams-examples/target/kafka-streams-examples-${JAR_VERSION}-standalone.jar" ]] || (cd kafka-streams-examples && mvn clean package -DskipTests)
java -cp kafka-streams-examples/target/kafka-streams-examples-${JAR_VERSION}-standalone.jar io.confluent.examples.streams.interactivequeries.kafkamusic.KafkaMusicExampleDriver &>/dev/null &

sleep 5

ksql http://localhost:8088 <<EOF
run script 'ksql.commands';
exit ;
EOF
