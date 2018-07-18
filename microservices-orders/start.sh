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

# Get random port number
RESTPORT=$(jot -r 1  10000 65000)
COUNT=0
while [[ $(netstat -ant | grep $RESTPORT) != "" ]]; do
  RESTPORT=$(jot -r 1  10000 65000)
  COUNT=$((COUNT+1))
  if [[ $COUNT > 5 ]]; then
    echo "Could not allocate a free rest port. Please troubleshoot"
    exit 1
  fi
done
echo "Port tcp:$RESTPORT looks free"

# Create topics
kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic orders
kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic order-validations
kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic warehouse-inventory
#kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic payments
#kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic customers

# Dlog4j.configuration=src/main/resources/log4j.properties

echo "Starting OrdersService"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.OrdersService -Dexec.args="localhost:9092 http://localhost:8081 localhost $RESTPORT" > /dev/null 2>&1 &
sleep 10
if [[ $(netstat -ant | grep $RESTPORT) == "" ]]; then
  echo "OrdersService not running on port $RESTPORT.  Please troubleshoot"
  exit 1
fi

for SERVICE in "InventoryService" "FraudService" "OrderDetailsService" "ValidationsAggregatorService"; do
    echo "Starting $SERVICE"
    mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.$SERVICE > /dev/null 2>&1 &
done

sleep 10

echo "Posting Order Requests"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.PostOrderRequests -Dexec.args="$RESTPORT" > /dev/null 2>&1 &

sleep 10

# Validate messages in topics
echo "-----orders-----"
confluent consume orders --value-format avro --max-messages 5
echo "-----order-validations-----"
confluent consume order-validations --value-format avro --max-messages 5
echo "-----warehouse-inventory-----"
confluent consume warehouse-inventory --max-messages 2 --from-beginning --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.IntegerDeserializer

# Requires EmailService to be populated with customer info
#echo "-----payments-----"
#confluent consume payments --value-format avro --max-messages 5
#echo "-----customers-----"
#confluent consume customers --value-format avro --max-messages 5

