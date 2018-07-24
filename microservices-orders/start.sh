#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_mvn || exit 1
check_running_cp 5.0 || exit 1

./stop.sh

# Compile java client code
[[ -d "kafka-streams-examples" ]] || git clone https://github.com/confluentinc/kafka-streams-examples.git
yes | cp -f *.java kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/.
(cd kafka-streams-examples && git checkout DEVX-147-phase2 && git fetch --prune ; git pull && mvn clean compile -DskipTests)
(cd kafka-streams-examples && mvn clean compile -DskipTests)
if [[ $? != 0 ]]; then
  echo "There seems to be a BUILD FAILURE error? Please troubleshoot"
  exit 1
fi

echo "auto.offset.reset=earliest" >> $CONFLUENT_HOME/etc/ksql/ksql-server.properties
confluent start
sleep 5

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
kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic customers
kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic payments

echo "Starting OrdersService"
(cd kafka-streams-examples && mvn exec:java -f pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.OrdersService -Dexec.args="localhost:9092 http://localhost:8081 localhost $RESTPORT" > /dev/null 2>&1 &)
sleep 10
if [[ $(netstat -ant | grep $RESTPORT) == "" ]]; then
  echo "OrdersService not running on port $RESTPORT.  Please troubleshoot"
  exit 1
fi

echo "Adding Inventory"
COUNT_UNDERPANTS=75
COUNT_JUMPERS=20
(cd kafka-streams-examples && mvn exec:java -f pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.AddInventory -Dexec.args="$COUNT_UNDERPANTS $COUNT_JUMPERS" > /dev/null 2>&1 &)

# Kafka Connect to source customers from sqlite3 database and produce to Kafka topic "customers"
TABLE_CUSTOMERS=/usr/local/lib/table.customers
prep_sqltable_customers
if is_ce; then confluent config jdbc-customers -d ./connector_jdbc_customers.config; else confluent config jdbc-customers -d ./connector_jdbc_customers_oss.config; fi

# Cannot run EmailService without AvroSerialization error!
for SERVICE in "InventoryService" "FraudService" "OrderDetailsService" "ValidationsAggregatorService" "EmailService"; do
    echo "Starting $SERVICE"
    (cd kafka-streams-examples && mvn exec:java -f pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.$SERVICE > /dev/null 2>&1 &)
done

sleep 10

echo -e "\nPosting Order Requests and Payments"
(cd kafka-streams-examples && mvn exec:java -f pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.PostOrdersAndPayments -Dexec.args="$RESTPORT" > /dev/null 2>&1 &)

sleep 10

################################
# View messages in topics

# Topic customers: populated by Kafka Connect that uses the JDBC source connector to read customer data from a sqlite3 database
echo -e "\n-----customers-----"
confluent consume customers --value-format avro --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.LongDeserializer --from-beginning --max-messages 5

# Topic orders: populated by a POST to the OrdersService service. A unique order is requested 1 per second
echo -e "\n-----orders-----"
confluent consume orders --value-format avro --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --max-messages 5 

# Topic payments: populated by PostOrdersAndPayments writing to the topic after placing an order. One payment is made per order
echo -e "\n-----payments-----"
confluent consume payments --value-format avro --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --max-messages 5

# Topic order-validations: PASS/FAIL for each "checkType": ORDER_DETAILS_CHECK (OrderDetailsService), FRAUD_CHECK (FraudService), INVENTORY_CHECK (InventoryService)
echo -e "\n-----order-validations-----"
confluent consume order-validations --value-format avro --max-messages 15

# Topic warehouse-inventory: initial inventory in stock
echo -e "\n-----warehouse-inventory-----"
confluent consume warehouse-inventory --max-messages 2 --from-beginning --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.IntegerDeserializer

# Topic inventory-service-store-of-reserved-stock-changelog: table backing the reserved inventory
# It maxes out when orders = initial inventory
echo -e "\n-----inventory-service-store-of-reserved-stock-changelog-----"
confluent consume inventory-service-store-of-reserved-stock-changelog --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer -from-beginning --max-messages $COUNT_JUMPERS


# Create KSQL queries
ksql http://localhost:8088 <<EOF
run script 'ksql.commands';
exit ;
EOF

# Read queries
timeout 5s ksql http://localhost:8088 <<EOF
SELECT * FROM ORDER_VALIDATIONS LIMIT 10;
exit ;
EOF

