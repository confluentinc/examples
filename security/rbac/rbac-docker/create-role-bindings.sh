#!/bin/bash -e

################################## SETUP VARIABLES #############################
MDS_URL=http://localhost:8090
CONNECT=connect-cluster
SR=schema-registry
KSQL=ksql-cluster
C3=c3-cluster

SUPER_USER=professor
SUPER_PASSWORD=professor
CONNECT_PRINCIPAL="User:fry"
SR_PRINCIPAL="User:leela"
KSQL_PRINCIPAL="User:zoidberg"
C3_PRINCIPAL="User:hermes"


wait_200() {
    curl -i http://professor:professor@localhost:8090/security/1.0/roleNames 2> /dev/null | grep "200 OK"
}

# wait until MDS is up
echo -n "Waiting for MDS to be ready"
until wait_200; do
    if [ $? -eq 0 ]; then
        break
    else
        echo "."
        sleep 1
    fi
done
echo "MDS is ready!"

# login to mds
XX_CONFLUENT_USERNAME=professor XX_CONFLUENT_PASSWORD=professor confluent login --url $MDS_URL

################################### SCHEMA REGISTRY ###################################
echo "Creating Schema Registry role bindings"

# SecurityAdmin on SR cluster itself
confluent iam rolebinding create \
    --principal $SR_PRINCIPAL \
    --role SecurityAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

# ResourceOwner for groups and topics on broker
for resource in Topic:_schemas Group:schema-registry
do
    confluent iam rolebinding create \
        --principal $SR_PRINCIPAL \
        --role ResourceOwner \
        --resource $resource \
        --kafka-cluster-id $KAFKA_CLUSTER_ID
done

################################### CONNECT ###################################
echo "Creating Connect role bindings"

# SecurityAdmin on the connect cluster itself
confluent iam rolebinding create \
    --principal $CONNECT_PRINCIPAL \
    --role SecurityAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

# ResourceOwner for groups and topics on broker
declare -a ConnectResources=(
    "Topic:connect-configs"
    "Topic:connect-offsets"
    "Topic:connect-status"
    "Group:connect-cluster"
    "Group:secret-registry"
    "Topic:_secrets"
)
for resource in ${ConnectResources[@]}
do
    confluent iam rolebinding create \
        --principal $CONNECT_PRINCIPAL \
        --role ResourceOwner \
        --resource $resource \
        --kafka-cluster-id $KAFKA_CLUSTER_ID
done

################################### KSQL ###################################
echo "Creating KSQL role bindings"

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource KsqlCluster:ksql-cluster \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --ksql-cluster-id $KSQL

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Group:_confluent-ksql-${KSQL} \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:_confluent-ksql-${KSQL}_command_topic \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:${KSQL}ksql_processing_log \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

################################### C3 ###################################
echo "Creating C3 role bindings"

# C3 only needs SystemAdmin on the kafka cluster itself
confluent iam rolebinding create \
    --principal $C3_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID


######################### print cluster ids and users again to make it easier to copypaste ###########

echo "Finished setting up role bindings"
echo "    kafka cluster id: $KAFKA_CLUSTER_ID"
echo "    connect cluster id: $CONNECT"
echo "    schema registry cluster id: $SR"
echo "    ksql cluster id: $KSQL"
echo
echo "    connect service account: $CONNECT_PRINCIPAL"
echo "    schema registry service account: $SR_PRINCIPAL"
echo "    KSQL service account: $KSQL_PRINCIPAL"
echo "    C3 service account: $C3_PRINCIPAL"