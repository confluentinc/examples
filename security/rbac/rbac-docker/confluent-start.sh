#!/bin/bash -e

# make sure dependencies are installed
depends="docker confluent jq"
for value in $depends
do
    if ! check="$(type -p "$value")" || [[ -z check ]]; then
        echo "error: please install '$value' and retry"
        exit 1
    fi
done

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


