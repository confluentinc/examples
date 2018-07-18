#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_mvn || exit 1
check_running_cp 5.0 || exit 

./stop.sh

confluent start schema-registry
sleep 5

[[ -d "kafka-streams-examples" ]] || git clone https://github.com/confluentinc/kafka-streams-examples.git
(cd kafka-streams-examples && git checkout DEVX-147)
#[[ -d "kafka-streams-examples/target" ]] || (cd kafka-streams-examples && mvn clean package -DskipTests)
(cd kafka-streams-examples && mvn clean compile -DskipTests)

RESTPORT=53231

echo "Starting OrdersService"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.OrdersService -Dexec.args="localhost:9092 http://localhost:8081 localhost $RESTPORT" > /dev/null 2>&1 &

echo "Starting InventoryService"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.InventoryService > /dev/null 2>&1 &

echo "Starting FraudService"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.FraudService > /dev/null 2>&1 &

echo "Starting OrderDetailsService"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.OrderDetailsService > /dev/null 2>&1 &

echo "Starting ValidationsAggregatorService"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.ValidationsAggregatorService > /dev/null 2>&1 &

echo "Starting EmailService"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.EmailService > /dev/null 2>&1 &

sleep 5

echo "Starting PostOrderRequests"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.PostOrderRequests -Dexec.args="$RESTPORT" > /dev/null 2>&1 &

confluent consume orders --value-format avro --max-messages 5
confluent consume warehouse-inventory --max-messages 5

