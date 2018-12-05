![image](images/confluent-logo-300-2.png)

* [Overview](#overview)
* [Running The Demos](#running-the-demos)
* [Prerequisities](#prerequisites)


# Overview

There are multiple demos in this repo that showcase Kafka stream processing on the Confluent Platform.  Each demo resides in its own subfolder.

| Demo                                       | Local | Docker | Description 
| ------------------------------------------ | ----- | ------ | -------------------------------------------------------------------------------- 
| [ccloud](ccloud/README.md)                 |   [Y](ccloud/README.md)   |   [Y](ccloud/README.md)    | hybrid Kafka Clusters from Self-Hosted to Confluent Cloud
| [clickstream](clickstream/README.md)       |   [Y](clickstream/README.md)   |   [Y](https://docs.confluent.io/current/ksql/docs/tutorials/clickstream-docker.html#ksql-clickstream-docker)    | automated version of the [KSQL Clickstream demo](https://github.com/confluentinc/ksql/blob/master/ksql-clickstream-demo/non-docker-clickstream.md#clickstream-analysis)
| [clients](clients/README.md)               |   [Y](clients/README.md)   |   N    | Producers and consumers; non-Avro to Confluent Cloud or Avro to local install
| [connect-streams-pipeline](connect-streams-pipeline/README.md) |   [Y](connect-streams-pipeline/README.md)   |   N    | demonstrate various ways, with and without Kafka Connect, to get data into Kafka topics and then loaded for use by the Kafka Streams API
| [ksql-workshop](ksql-workshop/README.md)   |   [Y](ksql-workshop/README.md)   |   [Y](ksql-workshop/README.md)    | showcases Kafka stream processing using KSQL and can be run automated or self-guided as a KSQL workshop
| [microservices-orders](microservices-orders/README.md) |   [Y](microservices-orders/README.md)   |   N    | integrates the [Microservices Orders Demo Application](https://github.com/confluentinc/kafka-streams-examples/tree/5.0.x/src/main/java/io/confluent/examples/streams/microservices) into Confluent Platform
| [music](music/README.md)                   |   [Y](music/README.md)   |   [Y](music/README.md)    | KSQL version of the [Kafka Streams Demo Application](https://docs.confluent.io/current/streams/kafka-streams-examples/docs/index.html)
| [mysql-debezium](mysql-debezium/README.md) |   [Y](mysql-debezium/README.md)   |   N    | end-to-end streaming ETL with KSQL for stream processing using the [Debezium Connector for MySQL](http://debezium.io/docs/connectors/mysql/)
| [pageviews](pageviews/README.md)           |   [Y](pageviews/README.md)   |   [Y](https://docs.confluent.io/current/quickstart/ce-docker-quickstart.html#ce-docker-quickstart)    | [Confluent Platform Quickstart](https://docs.confluent.io/current/quickstart.html)
| [postgres-debezium-ksql-elasticsearch](postgres-debezium-ksql-elasticsearch/README.md) |   N   |   [Y](postgres-debezium-ksql-elasticsearch/README.md)    | enrich event stream data with CDC data from Postgres and then stream into Elasticsearch
| [wikipedia](wikipedia/README.md)           |   [Y](wikipedia/README.md)   |   [Y](https://github.com/confluentinc/cp-demo)    | [Confluent Platform Demo](https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html) with a playbook for Kafka streaming ETL deployments

# Running The Demos

1. Clone the repo: `git clone https://github.com/confluentinc/examples`
2. Change directory to one of the demo subfolders
3. Read the `README.md` for each demo for precise instructions for each demo

# Prerequisites

For local installs:

* [Confluent Platform 5.0](https://www.confluent.io/download/)
* Env var `CONFLUENT_HOME=/path/to/confluentplatform`
* Env var `PATH` includes `$CONFLUENT_HOME/bin`
* Each demo has its own set of prerequisites as well, documented in each demo's README

For Docker:

* Docker version 17.06.1-ce
* Docker Compose version 1.14.0 with Docker Compose file format 2.1
