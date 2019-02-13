![image](images/confluent-logo-300-2.png)

* [Demo list](#demo-list)
* [Running demos](#running-demos)
* [Prerequisities](#prerequisites)


# What is this repo?

This repo contains a collection of demos that showcase Kafka stream processing on the Confluent Platform.
Some of the demos run on local Confluent Platform installs (download [Confluent Platform](https://www.confluent.io/download/)) and others run on Docker (install [Docker](https://docs.docker.com/install/) and [Docker Compose](https://docs.docker.com/compose/install/)). All of them contain READMEs that tell you what each demo does and how to run it, and all of them are tested against the latest Confluent Platform release.

## What should I do with it?

1. You should browse the demos, see which one sounds interesting, then run it!
2. If you want us to make it easy on you, try the [pageviews](pageviews/README.md) demo first. It's an automated version of the standard Confluent Platform Quickstart, and showcases a number of Platform features.
3. Before long, you should graduate to [cp-demo](https://github.com/confluentinc/cp-demo), which is a fully-integrated, Docker-based demo that spins up a Kafka event streaming application that showcases all parts of the Confluent Platform. It is actually several demos in one, so it comes with [a playbook and video series](https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html) to help guide you.

## The Full List of Demos

| Demo                                       | Local | Docker | Description 
| ------------------------------------------ | ----- | ------ | -------------------------------------------------------------------------------- 
| [ccloud](ccloud/README.md)                 |   [Y](ccloud/README.md)   |   [Y](ccloud/README.md)    | End-to-end demo of a hybrid Kafka Cluster between Confluent Cloud and on-prem
| [clickstream](clickstream/README.md)       |   [Y](clickstream/README.md)   |   [Y](https://docs.confluent.io/current/ksql/docs/tutorials/clickstream-docker.html#ksql-clickstream-docker)    | automated version of the [KSQL Clickstream demo](https://docs.confluent.io/current/ksql/docs/tutorials/clickstream-docker.html#ksql-clickstream-docker)
| [clients](clients/README.md)               |   [Y](clients/README.md)   |   N    | Examples of client applications in different programming languages: producers/consumers to Confluent Cloud, Avro/SR to local install
| [connect-streams-pipeline](connect-streams-pipeline/README.md) |   [Y](connect-streams-pipeline/README.md)   |   N    | Demonstrate various ways, with and without Kafka Connect, to get data into Kafka topics and then loaded for use by the Kafka Streams API
| [cp-demo](wikipedia/README.md)           |   [Y](wikipedia/README.md)   |   [Y](https://github.com/confluentinc/cp-demo)    | [Confluent Platform Demo](https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html) with a playbook for Kafka streaming ETL deployments
| [ksql-workshop](ksql-workshop/README.md)   |   [Y](ksql-workshop/README.md)   |   [Y](ksql-workshop/README.md)    | Showcases Kafka stream processing using KSQL and can be run automated or self-guided as a KSQL workshop
| [microservices-orders](microservices-orders/README.md) |   [Y](microservices-orders/README.md)   |   N    | Integrates the [Microservices Orders Demo Application](https://github.com/confluentinc/kafka-streams-examples/tree/5.1.1-post/src/main/java/io/confluent/examples/streams/microservices) into Confluent Platform
| [multi datacenter](https://github.com/confluentinc/cp-docker-images/tree/5.1.1-post/examples/multi-datacenter) | N | [Y](https://github.com/confluentinc/cp-docker-images/tree/5.1.1-post/examples/multi-datacenter) | This demo deploys an active-active multi-datacenter design, with two instances of Confluent Replicator copying data bidirectionally between the datacenters
| [music](music/README.md)                   |   [Y](music/README.md)   |   [Y](music/README.md)    | KSQL version of the [Kafka Streams Demo Application](https://docs.confluent.io/current/streams/kafka-streams-examples/docs/index.html)
| [mysql-debezium](mysql-debezium/README.md) |   [Y](mysql-debezium/README.md)   |   N    | End-to-end streaming ETL with KSQL for stream processing using the [Debezium Connector for MySQL](http://debezium.io/docs/connectors/mysql/)
| [oracle-ksql-elasticsearch](https://github.com/confluentinc/demo-scene/blob/master/oracle-ksql-elasticsearch/oracle-ksql-elasticsearch-docker.adoc) |   N   |   Y    | Stream data from Oracle, enrich and filter with KSQL, and then stream into Elasticsearch
| [pageviews](pageviews/README.md)           |   [Y](pageviews/README.md)   |   [Y](https://docs.confluent.io/current/quickstart/ce-docker-quickstart.html#ce-docker-quickstart)    | [Confluent Platform Quickstart](https://docs.confluent.io/current/quickstart.html)
| [postgres-debezium-ksql-elasticsearch](postgres-debezium-ksql-elasticsearch/README.md) |   N   |   [Y](postgres-debezium-ksql-elasticsearch/README.md)    | Enrich event stream data with CDC data from Postgres and then stream into Elasticsearch

# Prerequisites

For local installs:

* [Confluent Platform 5.1](https://www.confluent.io/download/)
* Env var `CONFLUENT_HOME=/path/to/confluentplatform`
* Env var `PATH` includes `$CONFLUENT_HOME/bin`
* Each demo has its own set of prerequisites as well, documented in each demo's README

For Docker:

* Docker version 17.06.1-ce or later
* Docker Compose version 1.14.0 or later with Docker Compose file format 2.1
