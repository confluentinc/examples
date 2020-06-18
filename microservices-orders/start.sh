#!/bin/bash

# Source library
source ../utils/helper.sh

check_env || exit 1
check_mvn || exit 1
check_jot || exit 1
check_netstat || exit 1
check_running_elasticsearch 5.6.16 || exit 1
check_running_kibana || exit 1
check_running_cp ${CONFLUENT} || exit 1
check_sqlite3 || exit 1

./stop.sh

get_and_compile_kafka_streams_examples || exit 1

confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:$CONFLUENT
confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:$CONFLUENT
grep -qxF 'auto.offset.reset=earliest' $CONFLUENT_HOME/etc/ksqldb/ksql-server.properties || echo 'auto.offset.reset=earliest' >> $CONFLUENT_HOME/etc/ksqldb/ksql-server.properties 
confluent local start
sleep 5

export BOOTSTRAP_SERVER=localhost:9092
export SCHEMA_REGISTRY_URL=http://localhost:8081
export SQLITE_DB_PATH=${PWD}/db/data/microservices.db
export ELASTICSEARCH_URL=http://localhost:9200

mkdir -p "$(pwd)"/db/data
mkdir -p "$(pwd)"/connectors/rendered-connectors

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

echo "Creating demo topics"
./scripts/create-topics.sh

echo "Setting up sqlite DB"
(cd db; ./setup-local-sql.sh)

echo "Configuring Elasticsearch and Kibana"
./dashboard/set_elasticsearch_mapping.sh
./dashboard/configure_kibana_dashboard.sh

echo "Submitting connectors"

# Kafka Connect to source customers from sqlite3 database and produce to Kafka topic "customers"
INPUT_FILE=./connectors/connector_jdbc_customers_template.config OUTPUT_FILE=./connectors/rendered-connectors/connector_jdbc_customers.config ./scripts/render-connector-config.sh
confluent local config jdbc-customers -- -d ./connectors/rendered-connectors/connector_jdbc_customers.config

# Sink Connector -> Elasticsearch -> Kibana
INPUT_FILE=./connectors/connector_elasticsearch_template.config OUTPUT_FILE=./connectors/rendered-connectors/connector_elasticsearch.config ./scripts/render-connector-config.sh
confluent local config elasticsearch -- -d ./connectors/rendered-connectors/connector_elasticsearch.config

echo "Starting OrdersService"
(cd kafka-streams-examples && mvn exec:java -f pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.OrdersService -Dexec.args="$BOOTSTRAP_SERVER http://localhost:8081 localhost $RESTPORT" > /dev/null 2>&1 &)
sleep 10
if [[ $(netstat -ant | grep $RESTPORT) == "" ]]; then
  echo "OrdersService not running on port $RESTPORT.  Please troubleshoot"
  exit 1
fi

echo "Adding Inventory"
COUNT_UNDERPANTS=25
COUNT_JUMPERS=20
(cd kafka-streams-examples && mvn exec:java -f pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.AddInventory -Dexec.args="$COUNT_UNDERPANTS $COUNT_JUMPERS" > /dev/null 2>&1 &)

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
run script 'statements.sql';
exit ;
EOF

./read-topics.sh

