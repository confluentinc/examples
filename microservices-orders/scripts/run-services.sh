#!/bin/bash

set -m

BOOTSTRAP_SERVER=${BOOTSTRAP_SERVER:-broker:9092}
SCHEMA_REGISTRY_URL=${SCHEMA_REGISTRY_URL:-http://schema-registry:8081}
RESTPORT=${RESTPORT:-18894}
JAR=${JAR:-"/usr/share/java/kafka-streams-examples/kafka-streams-examples-$CONFLUENT-standalone.jar"}
PIDS=()
echo "Starting OrdersService"
java -cp $JAR io.confluent.examples.streams.microservices.OrdersService $BOOTSTRAP_SERVER $SCHEMA_REGISTRY_URL localhost $RESTPORT &
PIDS+=($!)
sleep 10

echo "Adding Inventory"
java -cp $JAR io.confluent.examples.streams.microservices.AddInventory 20 20 $BOOTSTRAP_SERVER &
sleep 5

for SERVICE in "InventoryService" "FraudService" "OrderDetailsService" "ValidationsAggregatorService" "EmailService"; do
  echo "Starting $SERVICE"
  java -cp $JAR io.confluent.examples.streams.microservices.$SERVICE $BOOTSTRAP_SERVER $SCHEMA_REGISTRY_URL &
  PIDS+=($!)
done
sleep 10

echo "Posting Orders and Payments"
java -cp $JAR io.confluent.examples.streams.microservices.PostOrdersAndPayments $RESTPORT $BOOTSTRAP_SERVER $SCHEMA_REGISTRY_URL &
PIDS+=($1)
sleep 10

wait $PIDS
