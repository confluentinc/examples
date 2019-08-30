![image](../../images/confluent-logo-300-2.png)

# Overview

These demos showcase the [Role Based Access Control (RBAC)](https://docs.confluent.io/current/security/rbac/index.html) functionality in Confluent Platform. It is mostly for reference to see a workflow using the new RBAC feature across the services in Confluent Platform.

There are two demos.  Currently they have different configurations and can be used in different environments.

* [Demo 1: Local install](#demo-1-local-install)
* [Demo 2: Docker](#demo-2-docker)


# Demo 1: Local install

This demo is for users who have [downloaded](https://www.confluent.io/download/) Confluent Platform to their local hosts. 

## Caveats

* For simplicity, this demo does not use LDAP, instead it uses the Hash Login service with statically defined users/passwords. Additional configurations would be required if you wanted to augment the demo to connect to your LDAP server.
* The RBAC configurations and role bindings in this demo are not comprehensive, they are only for development to get minimum RBAC functionality set up across all the services in Confluent Platform. Please refer to the [RBAC documentation](https://docs.confluent.io/current/security/rbac/index.html) for comprehensive configuration and production guidance.

## Prerequisites

1. [Confluent CLI](https://docs.confluent.io/current/cli/installing.html): `confluent` CLI must be installed on your machine, version `v0.127.0` or higher (note: as of CP 5.3, the Confluent CLI is a separate [download](https://docs.confluent.io/current/cli/installing.html))
2. [Confluent Platform 5.3](https://www.confluent.io/download/): use a clean install of Confluent Platform without modified properties files, or else the demo is not guaranteed to work
3. `jq`

## Run the demo

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
$ ./enable-rbac-ksql-server.sh
$ ./enable-rbac-control-center.sh
```

3. After you run the demo, view the configuration files:

```bash
# The original configuration bundled with Confluent Platform
$ ls /tmp/original_configs/

# Configurations added to each service's properties file
$ ls ../delta_configs/

# The modified configuration = original + delta
$ ls /tmp/rbac_configs/
```

4. After you run the demo, view the log files for each of the services. Since this demo uses Confluent CLI, all logs are saved in a temporary directory specified by `confluent local current`.

```bash
$ ls `confluent local current | tail -1`
connect
control-center
kafka
kafka-rest
ksql-server
schema-registry
zookeeper
```

5. In this demo, the metadata service (MDS) logs are saved in the above temporary directory.

```bash
$ cat `confluent local current | tail -1`/kafka/logs/metadata-service.log
```

## Stop the demo

To stop the demo, stop Confluent Platform, and delete files in `/tmp/`

```bash
$ cd scripts
$ ./cleanup.sh
```

## Summary of Configurations and Role Bindings

Here is a summary of the delta configurations and required role bindings, by service.

Reminder: for simplicity, this demo uses the Hash Login service instead of LDAP.
If you are using LDAP in your environment, extra configurations are required.

### Broker

* [delta_configs/server.properties.delta](delta_configs/server.properties.delta)
* Role bindings:

```bash
# Broker Admin
confluent iam rolebinding create --principal User:$USER_ADMIN_SYSTEM --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID

# Producer/Consumer
confluent iam rolebinding create --principal User:$USER_CLIENT_A --role ResourceOwner --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_CLIENT_A --role DeveloperRead --resource Group:console-consumer- --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
```

### Schema Registry

* [delta_configs/schema-registry.properties.delta](delta_configs/schema-registry.properties.delta)
* Role bindings:

```bash
# Schema Registry Admin
confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Topic:_schemas --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Group:$SCHEMA_REGISTRY_CLUSTER_ID --kafka-cluster-id $KAFKA_CLUSTER_ID

# Client connecting to Schema Registry
 confluent iam rolebinding create --principal User:$USER_CLIENT_A --role ResourceOwner --resource Subject:$SUBJECT --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID
```

### Connect

* [delta_configs/connect-avro-distributed.properties.delta](delta_configs/connect-avro-distributed.properties.delta)
* [delta_configs/connector-source.properties.delta](delta_configs/connector-source.properties.delta)
* [delta_configs/connector-sink.properties.delta](delta_configs/connector-sink.properties.delta)
* Role bindings:

```bash
# Connect Admin
confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-configs --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-offsets --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-statuses --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Group:connect-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:_secrets --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role ResourceOwner --resource Group:secret-registry --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID

# Connector Submitter
confluent iam rolebinding create --principal User:$USER_CONNECTOR_SUBMITTER --role ResourceOwner --resource Connector:$CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID

# Connector
confluent iam rolebinding create --principal User:$USER_CONNECTOR --role ResourceOwner --resource Topic:$TOPIC2_AVRO --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_CONNECTOR --role ResourceOwner --resource Subject:${TOPIC2_AVRO}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID
```


### REST Proxy

* [delta_configs/kafka-rest.properties.delta](delta_configs/kafka-rest.properties.delta)
* Role bindings:

```bash
# REST Proxy Admin: no additional administrative rolebindings required because REST Proxy just does impersonation

# Producer/Consumer
confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role ResourceOwner --resource Topic:$TOPIC3 --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role DeveloperRead --resource Group:$CONSUMER_GROUP --kafka-cluster-id $KAFKA_CLUSTER_ID
```


### KSQL

* [delta_configs/ksql-server.properties.delta](delta_configs/ksql-server.properties.delta)
* Role bindings:

```bash
# KSQL Server Admin
confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}_command_topic --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID
confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID

# KSQL CLI queries
confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperWrite --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID
confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role DeveloperRead --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${USER_KSQL} --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}transient --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}transient --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
```

### General Rolebinding Syntax
General rolebinding syntax
```
confluent iam rolebinding create --role [role name] --principal User:[username] --resource [resource type]:[resource name] --[cluster type]-cluster-id [insert cluster id] 
```
available role types and permissions can be found [Here](https://docs.confluent.io/current/security/rbac/rbac-predefined-roles.html)

resource types include: Cluster, Group, Subject, Connector, TransactionalId, Topic

### Listing a Users roles
General Listing syntax
``` 
confluent iam rolebinding list User:[username] [clusters and resources you want to view their roles on]
```
example, list the roles of `User:bender` on Kafka cluster `KAFKA_CLUSTER_ID`
```
confluent iam rolebinding list --principal User:bender --kafka-cluster-id $KAFKA_CLUSTER_ID 
```

### Control Center

* [delta_configs/control-center-dev.properties.delta](delta_configs/control-center-dev.properties.delta)
* Role bindings:

```bash
# Control Center Admin
confluent iam rolebinding create --principal User:$USER_ADMIN_C3 --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID

# Control Center user
confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Topic:$TOPIC2_AVRO --kafka-cluster-id $KAFKA_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Subject:${TOPIC2_AVRO}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_ADMIN_C3 --role ClusterAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID
confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Connector:$CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID
```

# Demo 2: Docker

Follow directions in [rbac-docker/README.md](rbac-docker/README.md).

