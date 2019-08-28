#!/bin/bash -e

################################## GET KAFKA CLUSTER ID ########################
ZK_CONTAINER=zookeeper
ZK_PORT=2181
echo "Retrieving Kafka cluster id from docker-container '$ZK_CONTAINER' port '$ZK_PORT'"
KAFKA_CLUSTER_ID=$(docker exec -it $ZK_CONTAINER zookeeper-shell localhost:$ZK_PORT get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)
if [ -z "$KAFKA_CLUSTER_ID" ]; then 
    echo "Failed to retrieve kafka cluster id from zookeeper"
    exit 1
fi

################################## SETUP VARIABLES #############################
MDS_URL=http://localhost:8090
CONNECT=connect-cluster
SR=schema-registry
KSQL=ksql-cluster
C3=c3-cluster

SUPER_USER=professor
SUPER_USER_PASSWORD=professor
SUPER_USER_PRINCIPAL="User:$SUPER_USER"
CONNECT_PRINCIPAL="User:fry"
SR_PRINCIPAL="User:leela"
KSQL_PRINCIPAL="User:zoidberg"
C3_PRINCIPAL="User:hermes"

XX_CONFLUENT_USERNAME=$SUPER_USER XX_CONFLUENT_PASSWORD=$SUPER_USER_PASSWORD confluent login --url $MDS_URL

################################### SETUP SUPERUSER ###################################
echo "Creating Super User role bindings"

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL  \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --ksql-cluster-id $KSQL

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
echo "    super user account: $SUPER_USER_PRINCIPAL"
echo "    connect service account: $CONNECT_PRINCIPAL"
echo "    schema registry service account: $SR_PRINCIPAL"
echo "    KSQL service account: $KSQL_PRINCIPAL"
echo "    C3 service account: $C3_PRINCIPAL"

echo
echo "To set service IDs as environment variables paste/run this in your shell:"
echo "    export KAFKA_ID=$KAFKA_CLUSTER_ID ; export CONNECT_ID=$CONNECT ; export SR_ID=$SR ; export KSQL_ID=$KSQL"