#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_mvn || exit 1
check_running_cp 5.0 || exit 1

# Create the SQL table
TABLE_CUSTOMERS=/usr/local/lib/table.customers
prep_sqltable_customers

exit


./stop.sh

confluent start
sleep 5

[[ -d "kafka-streams-examples" ]] || git clone https://github.com/confluentinc/kafka-streams-examples.git
yes | cp -f PostOrderRequests.java kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/.
yes | cp -f AddInventory.java kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/.
(cd kafka-streams-examples && git checkout DEVX-147 && mvn clean compile -DskipTests)
if [[ $? != 0 ]]; then
  echo "There seems to be a BUILD FAILURE error? Please troubleshoot"
  exit 1
fi

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

echo "Adding Inventory"
COUNT_UNDERPANTS=75
COUNT_JUMPERS=20
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.AddInventory -Dexec.args="$COUNT_UNDERPANTS $COUNT_JUMPERS" > /dev/null 2>&1 &

for SERVICE in "InventoryService" "FraudService" "OrderDetailsService" "ValidationsAggregatorService"; do
    echo "Starting $SERVICE"
    mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.$SERVICE > /dev/null 2>&1 &
done

sleep 10

echo "Posting Order Requests"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.PostOrderRequests -Dexec.args="$RESTPORT" > /dev/null 2>&1 &

sleep 10

# Topic orders: a unique order is requested 1 per second
echo "-----orders-----"
confluent consume orders --value-format avro --max-messages 5

# Topic order-validations: PASS/FAIL for each "checkType": ORDER_DETAILS_CHECK (OrderDetailsService), FRAUD_CHECK (FraudService), INVENTORY_CHECK (InventoryService)
echo "-----order-validations-----"
confluent consume order-validations --value-format avro --max-messages 5

# Topic warehouse-inventory: initial inventory in stock
echo "-----warehouse-inventory-----"
confluent consume warehouse-inventory --max-messages 2 --from-beginning --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.IntegerDeserializer

# Topic inventory-service-store-of-reserved-stock-changelog: table backing the reserved inventory
# It maxes out when orders = initial inventory
echo "-----inventory-service-store-of-reserved-stock-changelog-----"
confluent consume inventory-service-store-of-reserved-stock-changelog --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer -from-beginning --max-messages $COUNT_JUMPERS

# Requires EmailService to be populated with customer info
#echo "-----payments-----"
#confluent consume payments --value-format avro --max-messages 5
#echo "-----customers-----"
#confluent consume customers --value-format avro --max-messages 5

