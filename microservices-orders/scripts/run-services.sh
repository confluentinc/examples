#!/bin/bash

set -m

BOOTSTRAP_SERVER=${BOOTSTRAP_SERVER:-broker:9092}
SCHEMA_REGISTRY_URL=${SCHEMA_REGISTRY_URL:-http://schema-registry:8081}
RESTPORT=${RESTPORT:-18894}
JAR=${JAR:-"/usr/share/java/kafka-streams-examples/kafka-streams-examples-$CONFLUENT-standalone.jar"}
PIDS=()
[[ -z "$CONFIG_FILE" ]] && CONFIG_FILE_ARG="" || CONFIG_FILE_ARG="--config-file $CONFIG_FILE"
ADDITIONAL_ARGS=${ADDITIONAL_ARGS:-""}
LOG_DIR=${LOG_DIR:="logs"}
PIDS_FILE=${PIDS_FILE:=".microservices.pids"}

echo "Config File arg: $CONFIG_FILE_ARG"
echo "Additional Args: $ADDITIONAL_ARGS"
echo "Starting microservices from $JAR"
echo "Connecting to cluster @ $BOOTSTRAP_SERVER and Schema Registry @ $SCHEMA_REGISTRY_URL"

echo "Starting OrdersService"
java -cp $JAR io.confluent.examples.streams.microservices.OrdersService --bootstrap-server $BOOTSTRAP_SERVER --schema-registry $SCHEMA_REGISTRY_URL --port $RESTPORT $CONFIG_FILE_ARG $ADDITIONAL_ARGS >$LOG_DIR/OrdersService.log 2>&1 &
PIDS+=($!)
sleep 10

echo "Adding Inventory"
java -cp $JAR io.confluent.examples.streams.microservices.AddInventory --bootstrap-server $BOOTSTRAP_SERVER $CONFIG_FILE_ARG $ADDITIONAL_ARGS >$LOG_DIR/AddInventory.log 2>&1 &
sleep 5

for SERVICE in "InventoryService" "FraudService" "OrderDetailsService" "ValidationsAggregatorService" "EmailService"; do
  echo "Starting $SERVICE"
  java -cp $JAR io.confluent.examples.streams.microservices.$SERVICE --bootstrap-server $BOOTSTRAP_SERVER --schema-registry $SCHEMA_REGISTRY_URL $CONFIG_FILE_ARG $ADDITIONAL_ARGS >$LOG_DIR/$SERVICE.log 2>&1 &
  PIDS+=($!)
done
sleep 10

echo "Posting Orders and Payments"
java -cp $JAR io.confluent.examples.streams.microservices.PostOrdersAndPayments --bootstrap-server $BOOTSTRAP_SERVER --schema-registry $SCHEMA_REGISTRY_URL --order-service-url "http://localhost:$RESTPORT" $CONFIG_FILE_ARG >$LOG_DIR/PostOrdersAndPayments.log 2>&1 &

PIDS+=($!)
sleep 10

echo "Microservice processes running under PIDS: ${PIDS[@]}"
echo "${PIDS[@]}" > $PIDS_FILE 
wait $PIDS

