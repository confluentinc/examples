#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_mvn || exit 1
check_running_cp 5.0 || exit 1

./stop.sh

confluent start schema-registry
sleep 5

[[ -d "kafka-streams-examples" ]] || git clone https://github.com/confluentinc/kafka-streams-examples.git
(cd kafka-streams-examples && git checkout DEVX-147 && mvn clean compile -DskipTests)

# Create topics
kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic orders
kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic payments
kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic customers
kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic order-validations
kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic warehouse-inventory

RESTPORT=$(jot -r 1  10000 65000)

# Dlog4j.configuration=src/main/resources/log4j.properties

echo "Starting OrdersService"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.OrdersService -Dexec.args="localhost:9092 http://localhost:8081 localhost $RESTPORT" > /dev/null 2>&1 &

sleep 10
if [[ $(netstat -ant | grep $RESTPORT) == "" ]]; then
  echo "OrdersService not running on port $RESTPORT.  Please troubleshoot"
  exit 1
else
  echo "OrdersService running on port $RESTPORT"
fi

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

echo "Posting Order Requests"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.PostOrderRequests -Dexec.args="$RESTPORT" > /dev/null 2>&1 &

# Validate messages in topics
confluent consume orders --value-format avro --max-messages 5
confluent consume payments --value-format avro --max-messages 5
confluent consume customers --value-format avro --max-messages 5
confluent consume order-validations --value-format avro --max-messages 5
confluent consume warehouse-inventory --max-messages 5

