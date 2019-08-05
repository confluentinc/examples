![image](../images/confluent-logo-300-2.png)

# Overview

This Confluent Cloud demo showcases a hybrid Kafka deployment: one cluster is a self-managed cluster running locally, the other is a |ccloud| cluster.
Data streams into topics both a local cluster and a cluster in Confluent Cloud, and Replicator copies the on-prem data to Cloud so that stream processing can happen in the Cloud.

Note: if you are looking for code examples of producers writing to and consumers reading from Confluent Cloud, or producers and consumers using Avro with Confluent Schema Registry, checkout the [clients subdirectory of examples](../clients). It provides client examples written in various programming languages.

This automated demo is an expansion of the [KSQL Tutorial](https://docs.confluent.io/current/ksql/docs/tutorials/basics-local.html#create-a-stream-and-table>). Instead of the Kafka cluster backing the KSQL stream processing running on your local install, it runs on your Confluent Cloud cluster. There are also additional Confluent Platform components including Confluent Control Center and Confluent Replicator.

![image](docs/images/schema-registry-local.jpg)

## End-to-end Solution

This demo showcases:

* Confluent Cloud
* Confluent Cloud Schema Registry
* KSQL
* Confluent Replicator
* Confluent Control Center
* Kafka Connect
* `kafka-connect-datagen` connectors


## Per-component Delta Configurations to Connect to Confluent Cloud

It also includes a [script](ccloud-generate-cp-configs.sh) that reads the Confluent Cloud configuration in ``$HOME/.ccloud/config`` and writes delta configuration files into ``./delta_configs`` for Confluent Platform components and clients connecting to Confluent Cloud.  See the [template examples](template_delta_configs) for examples of lines to add to each component or client.

* Confluent Platform Components:
  * Confluent Schema Registry
  * KSQL Data Generator
  * KSQL server
  * Confluent Replicator (standalone binary)
  * Confluent Control Center
  * Kafka Connect
* Kafka Clients:
  * Java (Producer/Consumer)
  * Java (Streams)
  * Python
  * .NET
  * Go
  * Node.js (https://github.com/Blizzard/node-rdkafka)
  * C++

## ACL Demo

This [demo script](../security/acl.sh) showcases the Access Control List (ACL) functionality in your Confluent Cloud Enterprise cluster. It is mostly for reference to see a workflow using the *new* Confluent Cloud CLI (check your version with `ccloud version`).

```bash
$ ccloud version
ccloud - Confluent Cloud CLI

Version:     v0.130.0
Git Ref:     6a42a8de62b5335b6f17842e352d33586669ce16
Build Date:  2019-07-17T17:33:59Z
Build Host:  semaphore@semaphore-vm
Go Version:  go1.12.5 (darwin/amd64)
Development: false
```

# Prerequisites

## Confluent Cloud configuration file

First create a Confluent Cloud configuration file with information on connecting to your Confluent Cloud cluster.
By default, the demo looks for the configuration file at `~/.ccloud/config` (you can change this file location in `config.sh`).


```bash
$ cat ~/.ccloud/config
bootstrap.servers=<BROKER ENDPOINT>
ssl.endpoint.identification.algorithm=https
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
# If you are using Confluent Cloud Schema Registry
basic.auth.credentials.source=USER_INFO
schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
schema.registry.url=https://<SR ENDPOINT>
```

## Local

As with the other demos in this repo, you may run the entire demo end-to-end with `./start.sh`, and it runs on your local Confluent Platform install.  This requires the following:

* [Common demo prerequisites](https://github.com/confluentinc/examples#prerequisites)
* [Confluent Platform 5.3](https://www.confluent.io/download/)
* [Confluent Cloud CLI](https://docs.confluent.io/current/cloud-quickstart.html#step-2-install-ccloud-cli)
* [An initialized Confluent Cloud cluster used for development only](https://confluent.cloud)
* Maven to compile the data generator, i.e. the `KafkaMusicExampleDriver` class
* `jq` installed on your machine

To run the local setup:

```bash
$ ./start.sh
```

## Docker

* Docker version 17.06.1-ce
* Docker Compose version 1.14.0 with Docker Compose file format 2.1
* [Confluent Cloud CLI](https://docs.confluent.io/current/cloud-quickstart.html#step-2-install-ccloud-cli)
* [An initialized Confluent Cloud cluster used for development only](https://confluent.cloud)
* `jq` installed on your machine

To run the Docker setup:

```bash
$ ./start-docker.sh
```

NOTE: Do not run this demo against your production Confluent Cloud cluster. Run this demo only in a development cluster.

# Documentation

You can find the documentation for running this demo, and its accompanying playbook, at [https://docs.confluent.io/current/tutorials/examples/ccloud/docs/index.html](https://docs.confluent.io/current/tutorials/examples/ccloud/docs/index.html)
