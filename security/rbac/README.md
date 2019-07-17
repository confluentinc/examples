![image](../../images/confluent-logo-300-2.png)

# Overview

This demo showcases the [Role Based Access Control (RBAC)](https://docs.confluent.io/current/security/rbac/index.html) functionality in Confluent Platform. It is mostly for reference to see a workflow using the new RBAC feature across the services in Confluent Platform.

## Notes

* For simplicity, this demo does not require the use of LDAP. Instead it uses the Hash Login service with statically defined users/passwords

# Run the demo

## Prerequisites

1. [Confluent CLI](https://docs.confluent.io/current/cli/installing.html): `confluent` CLI must be installed on your machine, version `v0.127.0` or higher (note: as of CP 5.3, the Confluent CLI is a separate [download](https://docs.confluent.io/current/cli/installing.html)
2. [Confluent Platform 5.3](https://www.confluent.io/download/): use a clean install of Confluent Platform without modified properties files, or else the demo is not guaranteed to work
3. `jq`

## Execute the demo

1. Change directory into the `scripts` folder:

```bash
$ cd scripts
```

2. You have two options to run the demo.

* Option 1: run the demo end-to-end for all services

```bash
$ ./run.sh
```

* Option 2: step through it one service at a time

```bash
$ ./init.sh
$ ./enable-rbac-broker.sh
$ ./enable-rbac-schema-registry.sh
$ ./enable-rbac-connect.sh
$ ./enable-rbac-rest-proxy.sh
```

3. After you run the demo, view the configuration files:

```bash
# The original configuration bundled with Confluent Platform
$ ls /tmp/original_configs/

# Configurations added to each components' properties file
$ ls ../delta_configs/

# The modified configuration = original + delta
$ ls /tmp/rbac_configs/
```

## Stop the demo

To stop the demo, stop Confluent Platform, and delete files in `/tmp/`

```bash
$ cd scripts
$ ./cleanup.sh
```

# Summary of Configurations and Role Bindings

Here is a summary of the delta configurations and required role bindings, by component.

Reminder: for simplicity, this demo uses the Hash Login service instead of LDAP.
If you are using LDAP in your environment, extra configurations are required.

## Broker

* [delta_configs/server.properties.delta](delta_configs/server.properties.delta)
* Role bindings:

```bash
# Broker Admin
confluent iam rolebinding create --principal User $USER_ADMIN_SYSTEM --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID

# Producer/Consumer
confluent iam rolebinding create --principal User $USER_CLIENT_A --role ResourceOwner --resource Topic $TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_CLIENT_A --role DeveloperRead --resource Group console-consumer- --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
```

## Schema Registry

* [delta_configs/schema-registry.properties.delta](delta_configs/schema-registry.properties.delta)
* Role bindings:

```bash
# Schema Registry Admin
confluent iam rolebinding create --principal User $USER_ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Topic _schemas --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_ADMIN_SCHEMA_REGISTRY --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Group $SCHEMA_REGISTRY_CLUSTER_ID --kafka-cluster-id $KAFKA_CLUSTER_ID

# Client connecting to Schema Registry
 confluent iam rolebinding create --principal User $USER_CLIENT_A --role ResourceOwner --resource Subject $SUBJECT --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID
```

## Connect

* [delta_configs/connect-avro-distributed.properties.delta](delta_configs/connect-avro-distributed.properties.delta)
* [delta_configs/connector-source.properties.delta](delta_configs/connector-source.properties.delta)
* [delta_configs/connector-sink.properties.delta](delta_configs/connector-sink.properties.delta)
* Role bindings:

```bash
# Connect Admin
confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role ResourceOwner --resource Topic connect-configs --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role ResourceOwner --resource Topic connect-offsets --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role ResourceOwner --resource Topic connect-statuses --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role ResourceOwner --resource Group connect-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role ResourceOwner --resource Topic _secrets --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role ResourceOwner --resource Group secret-registry --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID

# Connector
confluent iam rolebinding create --principal User $USER_CLIENT_A --role ResourceOwner --resource Connector $CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_CLIENT_A --role ResourceOwner --resource Topic $TOPIC2_AVRO --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_CLIENT_A --role ResourceOwner --resource Subject ${TOPIC2_AVRO}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID
```


## REST Proxy

* [delta_configs/kafka-rest.properties.delta](delta_configs/kafka-rest.properties.delta)
* Role bindings:

```bash
# REST Proxy Admin: no additional administrative rolebindings required because REST Proxy just does impersonation

# Producer/Consumer
<<<<<<< HEAD
confluent iam rolebinding create --principal User $USER_CLIENT_RP --role ResourceOwner --resource Topic $TOPIC3 --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_CLIENT_RP --role DeveloperRead --resource Group $CONSUMER_GROUP --kafka-cluster-id $KAFKA_CLUSTER_ID
```


## KSQL

* [delta_configs/ksql-server.properties.delta](delta_configs/ksql-server.properties.delta)
* Role bindings:

```bash
# KSQL Server Admin
confluent iam rolebinding create --principal User:$ADMIN_KSQL --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}_command_topic --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$ADMIN_KSQL --role ResourceOwner --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$ADMIN_KSQL --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID
confluent iam rolebinding create --principal User:$ADMIN_KSQL --role ResourceOwner --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID

# KSQL CLI queries
confluent iam rolebinding create --principal User:${KSQL_USER} --role ResourceOwner --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID
confluent iam rolebinding create --principal User:${KSQL_USER} --role DeveloperManage --resource Cluster:kafka-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${KSQL_USER} --role ResourceOwner --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${KSQL_USER} --role ResourceOwner --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${KSQL_USER} --role DeveloperRead --resource Topic:$DATA_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${ADMIN_KSQL} --role DeveloperManage --resource Cluster:kafka-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${ADMIN_KSQL} --role ResourceOwner --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${ADMIN_KSQL} --role DeveloperRead --resource Topic:$DATA_TOPIC --kafka-cluster-id $KAFKA_CLUSTER_ID
```
