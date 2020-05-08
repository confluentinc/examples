![image](../images/confluent-logo-300-2.png)

* [Overview](#overview)
* [Warning](#warning)
* [Demos](#demos)

** [Confluent Quickstart](#confluent-quickstart)
** [Fully Managed Stack in Confluent Cloud](#fully-managed-stack-in-confluent-cloud)
** [Client Code Examples](#client-code-examples)
** [Confluent Cloud CLI Demo](#confluent-cloud-cli)
** [Cloud ETL](#cloud-etl)
** [Hybrid Cloud](#hybrid-cloud)

* [Build Your Own Cloud Demo](#build-your-own-cloud-demo)
* [Auto-generate Configurations to connect to Confluent Cloud](#auto-generate-configurations-to-connect-to-confluent-cloud)
* [Additional Resources](#additional-resources)


# Overview

[Confluent Cloud](https://docs.confluent.io/current/cloud/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud) is a resilient, scalable streaming data service based on Apache Kafka®, delivered as a fully managed service.
It has a web interface and local command line interface that you can use to manage cluster resources, Kafka topics, Schema Registry, and other services.

This repo has a few resources to help you validate your solutions on Confluent Cloud.

# Warning

All demos/scripts that connect to Confluent Cloud use real Confluent Cloud resources.
To avoid unexpected charges, carefully evaluate the cost of resources before launching any demo and ensure all resources are destroyed after you are done running it.

# Demos

## Confluent Quickstart

See the [cp-quickstart](../cp-quickstart) for an automated version of the Confluent Platform Quickstart, but this one running in Confluent Cloud.

## Fully Managed Stack in Confluent Cloud

The [ccloud stack](ccloud-stack/README.md) is a script that creates a stack of fully managed services in Confluent Cloud.
It is a quick way to create fully managed components in Confluent Cloud, which you can then use for learning and building other demos.
Please do not use this in a production environment.
The script uses the Confluent Cloud CLI to dynamically do the following in Confluent Cloud:

* Create a new environment
* Create a new service account
* Create a new Kafka cluster and associated credentials
* Enable Schema Registry and associated credentials
* Create a new KSQL app and associated credentials
* Create ACLs with wildcard for the service account
* Generate a local configuration file with all above connection information, useful for other demos/automation

To create the stack, it is one single command, see [instructions](ccloud-stack/README.md) for more info.

## Client Code Examples

If you are looking for code examples of producers writing to and consumers reading from Confluent Cloud, or producers and consumers using Avro with Confluent Schema Registry, checkout the [clients subdirectory of examples](../clients).
It provides client examples written in various programming languages.

![image](../clients/cloud/images/clients-all.png)

## Confluent Cloud CLI

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

## Cloud ETL

The [cloud ETL demo](https://docs.confluent.io/current/tutorials/examples/cloud-etl/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud) showcases a cloud ETL solution leveraging all fully-managed services on Confluent Cloud.
Using Confluent Cloud CLI, the demo creates a source connector that reads data from an AWS Kinesis stream into Confluent Cloud, then a Confluent Cloud KSQL application processes that data, and then a sink connector writes the output data into cloud storage in the provider of your choice (one of GCP GCS, AWS S3, or Azure Blob).

The documentation for running this demo is at [https://docs.confluent.io/current/tutorials/examples/cloud-etl/docs/index.html](https://docs.confluent.io/current/tutorials/examples/cloud-etl/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud)

![image](../cloud-etl/docs/images/topology.png)


## Hybrid Cloud

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


# Additional Resources

Refer to [Best Practices for Developing Kafka Applications on Confluent Cloud](https://assets.confluent.io/m/14397e757459a58d/original/20200205-WP-Best_Practices_for_Developing_Apache_Kafka_Applications_on_Confluent_Cloud.pdf?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud) whitepaper for a practical guide to configuring, monitoring, and optimizing your Kafka client applications when using Confluent Cloud.
