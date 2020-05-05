![image](../images/confluent-logo-300-2.png)

* [Overview](#overview)
* [Warning](#warning)
* [Confluent Cloud CLI Demo](#confluent-cloud-cli)
* [Fully Managed Stack in Confluent Cloud](#fully-managed-stack-in-confluent-cloud)
* [Hybrid Cloud](#hybrid-cloud)
* [Client Code Examples](#client-code-examples)
* [Build Your Own Cloud Demo](#build-your-own-cloud-demo)
* [Auto-generate Configurations to connect to Confluent Cloud](#auto-generate-configurations-to-connect-to-confluent-cloud)


# Overview

[Confluent Cloud](https://docs.confluent.io/current/cloud/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud) is a resilient, scalable streaming data service based on Apache Kafka®, delivered as a fully managed service.
It has a web interface and local command line interface that you can use to manage cluster resources, Kafka topics, Schema Registry, and other services.

This repo has a few resources to help you validate your solutions on Confluent Cloud.

# Warning

All demos/scripts that connect to Confluent Cloud use real Confluent Cloud resources.
To avoid unexpected charges, carefully evaluate the cost of resources before launching any demo and ensure all resources are destroyed after you are done running it.

# Confluent Cloud CLI

[This beginner demo](beginner-cloud/README.md) is a fully scripted demo that shows users how to interact with Confluent Cloud using the Confluent Cloud CLI.
It steps through the following workflow:

* Create a new environment and specify it as the default
* Create a new Kafka cluster and specify it as the default
* Create a user key/secret pair and specify it as the default
* Produce and consume with Confluent Cloud CLI
* Create a service account key/secret pair
* Run a Java producer: before and after ACLs
* Run a Java producer: showcase a Prefix ACL
* Run Connect and kafka-connect-datagen connector with permissions
* Run a Java consumer: showcase a Wildcard ACL
* Delete the API key, service account, Kafka topics, Kafka cluster, environment, and the log files


# Fully Managed Stack in Confluent Cloud

The [ccloud stack](beginner-cloud/ccloud_stack_spin_up.sh) is a script that uses the Confluent Cloud CLI to dynamically do the following things in Confluent Cloud:

* Create a new environment
* Create a new service account
* Create a new Kafka cluster and associated credentials
* Enable Schema Registry and associated credentials
* Create a new KSQL app and associated credentials
* Broad ACLs for the service account
* Local configuration file with connection information

To spin up the stack:

```bash
./ccloud_stack_spin_up.sh
...
To spin down this stack, run './ccloud_stack_spin_down.sh /tmp/client-<SERVICE_ACCOUNT_ID>.config'
```

To spin down the stack:

```bash
./ccloud stack_spin_down.sh /tmp/client-<SERVICE_ACCOUNT_ID>.config
```

# Cloud ETL

The [cloud ETL demo](https://docs.confluent.io/current/tutorials/examples/cloud-etl/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud) showcases a cloud ETL solution leveraging all fully-managed services on Confluent Cloud.
Using Confluent Cloud CLI, the demo creates a source connector that reads data from an AWS Kinesis stream into Confluent Cloud, then a Confluent Cloud KSQL application processes that data, and then a sink connector writes the output data into cloud storage in the provider of your choice (one of GCP GCS, AWS S3, or Azure Blob).

The documentation for running this demo is at [https://docs.confluent.io/current/tutorials/examples/cloud-etl/docs/index.html](https://docs.confluent.io/current/tutorials/examples/cloud-etl/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud)

![image](../cloud-etl/docs/images/topology.png)


# Hybrid Cloud

[This end-to-end Confluent Cloud demo](https://docs.confluent.io/current/tutorials/examples/ccloud/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud) showcases a hybrid Kafka deployment: one cluster is a self-managed cluster running locally, the other is a |ccloud| cluster.
Data streams into topics both a local cluster and a cluster in Confluent Cloud, and Confluent Replicator copies the on-prem data to Confluent Cloud so that stream processing can happen in the Cloud.

The documentation for running this demo, and its accompanying playbook, is at [https://docs.confluent.io/current/tutorials/examples/ccloud/docs/index.html](https://docs.confluent.io/current/tutorials/examples/ccloud/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud)

![image](docs/images/schema-registry-local.jpg)

It includes:

* Confluent Cloud
* Confluent Cloud Schema Registry
* ksqlDB
* Confluent Replicator
* Confluent Control Center
* Kafka Connect
* `kafka-connect-datagen` connectors

NOTE: Do not run this demo against your production Confluent Cloud cluster. Run this demo only in a development cluster.

# Client Code Examples

If you are looking for code examples of producers writing to and consumers reading from Confluent Cloud, or producers and consumers using Avro with Confluent Schema Registry, checkout the [clients subdirectory of examples](../clients).
It provides client examples written in various programming languages.

![image](../clients/cloud/images/clients-all.png)


# Build Your Own Cloud Demo

As a next step, you may want to build your own custom demo or test environment.
We have a Docker Compose file called [cp-all-in-one-cloud](../cp-all-in-one-cloud/README.md) -- use this with your existing Confluent Cloud instance.
This file launches all services in Confluent Platform (except for the Kafka brokers), runs them in containers in your local host, and automatically configures them to connect to Confluent Cloud.
Using this as a foundation, you can then add any connectors or applications.


# Auto-generate Configurations to connect to Confluent Cloud

[This script](ccloud-generate-cp-configs.sh) reads a configuration file (by default assumed to be at ``$HOME/.ccloud/config``) and auto-generates delta configurations into ``./delta_configs``.
Use these per-component configurations for Confluent Platform components and clients connecting to Confluent Cloud:

* Confluent Platform Components:
  * Confluent Schema Registry
  * ksqlDB Data Generator
  * ksqlDB server
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

The [template examples](template_delta_configs) have delta configuration lines to add to each component or client.
See [documentation](https://docs.confluent.io/current/cloud/connect/auto-generate-configs.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud) for more information.

