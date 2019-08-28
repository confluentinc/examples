#!/bin/bash -e

if [ -z "$1" ]; then
    PROJECT=rbac
else
    PROJECT=$1
fi

# Generating public and private keys for token signing
echo "Generating public and private keys for token signing"
mkdir -p ./conf
openssl genrsa -out ./conf/keypair.pem 2048
openssl rsa -in ./conf/keypair.pem -outform PEM -pubout -out ./conf/public.pem

# start broker
echo
echo "Starting Zookeeper, OpenLDAP and Kafka with MDS"
docker-compose -p $PROJECT up -d broker

ZK_HOST=localhost:2181
echo "Retrieving Kafka cluster id from zookeeper"
export KAFKA_CLUSTER_ID=$(zookeeper-shell $ZK_HOST get /cluster/id 2> /dev/null | grep version | jq -r .id)
if [ -z "$KAFKA_CLUSTER_ID" ]; then
    echo "Failed to retrieve kafka cluster id from zookeeper"
    exit 1
fi

# wait for kafka container to be healthy
source ./functions.sh
echo
echo "Waiting for the broker to be healthy"
retry 10 5 container_healthy broker

# set role bindings
echo
echo "Creating role bindings for service accounts"
./create-role-bindings.sh

# start the rest of the cluster
echo
echo "Starting the rest of the services"
docker-compose -p $PROJECT up -d

echo
echo "----------------------------------------------"
echo
echo "Started confluent cluster with rbac."
echo "Kafka is available at localhost:9092"
echo
echo "    See status:"
echo "          docker-compose -p $PROJECT ps"
echo "    To stop:"
echo "          docker-compose -p $PROJECT down"


wait_c3() {
    curl -i http://localhost:9021/2.0/feature/flags 2> /dev/null | grep "200 OK"
}
# wait until MDS is up
until wait_c3; do
    if [ $? -eq 0 ]; then
        echo "Control Center is ready at http://localhost:9021"
        break
    else
        echo "Waiting 5 more seconds for Control Center to come up..."
        sleep 5
    fi
done

export SR_CLUSTER_ID=schema-registry
export CONNECT_CLUSTER_ID=connect-cluster
export KSQL_CLUSTER_ID=ksql-cluster
echo
echo "----------------------------------------------"
echo
echo "Set environment variables:"
echo
echo "    export KAFKA_CLUSTER_ID=$KAFKA_CLUSTER_ID"
echo "    export SR_CLUSTER_ID=$SR_CLUSTER_ID"
echo "    export CONNECT_CLUSTER_ID=$CONNECT_CLUSTER_ID"
echo "    export KSQL_CLUSTER_ID=$KSQL_CLUSTER_ID"
echo
echo
echo "----------------------------------------------"
echo
echo "To set rolebindings, first login with professor:professor"
echo
echo "    confluent login --url http://localhost:8090"
echo