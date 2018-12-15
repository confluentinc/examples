#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_mvn || exit 1
check_jot || exit 1
check_netstat || exit 1
check_running_elasticsearch 5.6.5 || exit 1
check_running_kibana || exit 1
check_running_cp 5.1 || exit 1

./stop.sh

./get-kafka-streams-examples.sh
if [[ $? != 0 ]]; then
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
COUNT_UNDERPANTS=25
COUNT_JUMPERS=20
(cd kafka-streams-examples && mvn exec:java -f pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.AddInventory -Dexec.args="$COUNT_UNDERPANTS $COUNT_JUMPERS" > /dev/null 2>&1 &)

# Kafka Connect to source customers from sqlite3 database and produce to Kafka topic "customers"
prep_sqltable_customers
if is_ce; then confluent config jdbc-customers -d ./connectors/connector_jdbc_customers.config; else confluent config jdbc-customers -d ./connectors/connector_jdbc_customers_oss.config; fi

# Sink Connector -> Elasticsearch -> Kibana
if is_ce; then confluent config elasticsearch -d ./connectors/connector_elasticsearch.config; else confluent config elasticsearch -d ./connectors/connector_elasticsearch_oss.config; fi
./dashboard/set_elasticsearch_mapping.sh
./dashboard/configure_kibana_dashboard.sh

# Start microservices
for SERVICE in "InventoryService" "FraudService" "OrderDetailsService" "ValidationsAggregatorService" "EmailService"; do
    echo "Starting $SERVICE"
    (cd kafka-streams-examples && mvn exec:java -f pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.$SERVICE > /dev/null 2>&1 &)
done

sleep 10

echo -e "\nPosting Order Requests and Payments"
(cd kafka-streams-examples && mvn exec:java -f pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.PostOrdersAndPayments -Dexec.args="$RESTPORT" > /dev/null 2>&1 &)

sleep 10

# Create KSQL queries
ksql http://localhost:8088 <<EOF
run script 'ksql.commands';
exit ;
EOF


./read-topics.sh

