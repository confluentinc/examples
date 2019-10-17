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

It also includes a [script](ccloud-generate-cp-configs.sh) that reads the Confluent Cloud configuration in ``$HOME/.ccloud/config`` and writes delta configuration files into ``./delta_configs`` for Confluent Platform components and clients connecting to Confluent Cloud.
The [template examples](template_delta_configs) have delta configuration lines to add to each component or client.
See https://docs.confluent.io/current/cloud/connect/auto-generate-configs.html for more information.

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


# Running the demo

You can find the documentation for running this demo, and its accompanying playbook, at [https://docs.confluent.io/current/tutorials/examples/ccloud/docs/index.html](https://docs.confluent.io/current/tutorials/examples/ccloud/docs/index.html)

NOTE: Do not run this demo against your production Confluent Cloud cluster. Run this demo only in a development cluster.
