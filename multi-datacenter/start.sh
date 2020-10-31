#!/bin/bash

# Source library
source ../utils/helper.sh

check_jq || exit 1

docker-compose up -d

# Verify Kafka Connect workers have started
MAX_WAIT=120
echo "Waiting up to $MAX_WAIT seconds for Connect to start"
retry $MAX_WAIT check_connect_up connect-dc2 || exit 1
retry $MAX_WAIT check_connect_up connect-dc1 || exit 1
sleep 2 # give connect an exta moment to fully mature
echo "connect-dc1 and connect-dc2 have started!"

# Verify topics exist
MAX_WAIT=30
echo "Waiting up to $MAX_WAIT seconds for topics to exist"
retry $MAX_WAIT check_topic_exists broker-dc1 broker-dc1:9091 topic1 || exit 1
retry $MAX_WAIT check_topic_exists broker-dc1 broker-dc1:9091 topic2 || exit 1
retry $MAX_WAIT check_topic_exists broker-dc2 broker-dc2:9092 topic1 || exit 1
echo "Topics exist!"

echo -e "\n\nReplicator: dc1 topic1 -> dc2 topic1"
./submit_replicator_dc1_to_dc2.sh

echo -e "\n\nReplicator: dc1 topic2 -> dc2 topic2.replica"
./submit_replicator_dc1_to_dc2_topic2.sh

echo -e "\n\nReplicator: dc2 topic1 -> dc1 topic1"
./submit_replicator_dc2_to_dc1.sh

# Verify connectors are running
MAX_WAIT=60
echo
echo "Waiting up to $MAX_WAIT seconds for connectors to be in RUNNING state"
retry $MAX_WAIT check_connector_status_running 8382 replicator-dc1-to-dc2-topic1 || exit 1
retry $MAX_WAIT check_connector_status_running 8382 replicator-dc1-to-dc2-topic2 || exit 1
retry $MAX_WAIT check_connector_status_running 8381 replicator-dc2-to-dc1-topic1 || exit 1
echo "Connectors are running!"

# Register the same schema for the replicated topic topic2.replica as was created for the original topic topic2
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{\"schema\": $(curl -s http://localhost:8081/subjects/topic2-value/versions/latest | jq '.schema')}" http://localhost:8081/subjects/topic2.replica-value/versions
echo

# Verify Confluent Control Center has started
MAX_WAIT=300
echo "Waiting up to $MAX_WAIT seconds for Confluent Control Center to start"
retry $MAX_WAIT check_control_center_up control-center || exit 1

echo -e "\n\n\n******************************************************************"
echo -e "DONE! Connect to Confluent Control Center at http://localhost:9021"
echo -e "******************************************************************\n"
