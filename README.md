![image](images/confluent-logo-300-2.png)

* [Overview](#overview)
* [Running The Demos](#running-the-demos)
* [Prerequisities](#prerequisites)


# Overview

There are multiple demos in this repo that showcase Kafka stream processing on the Confluent Platform.  Each demo resides in its own subfolder.

| Demo                                       | Description 
| ------------------------------------------ | -------------------------------------------------------------------------------- 
| [ccloud](ccloud/README.md)                 | hybrid Kafka Clusters from Self-Hosted to Confluent Cloud, runs on your local install and Confluent Cloud cluster
| [clickstream](clickstream/README.md)       | automated version of the [KSQL Clickstream demo](https://github.com/confluentinc/ksql/blob/master/ksql-clickstream-demo/non-docker-clickstream.md#clickstream-analysis)
| [connect-streams-pipeline](connect-streams-pipeline/README.md) | demonstrate various ways, with and without Kafka Connect, to get data into Kafka topics and then loaded for use by the Kafka Streams API
| [ksql-workshop](ksql-workshop/README.md)   | showcases Kafka stream processing using KSQL and can be run automated or self-guided as a KSQL workshop
| [music](music/README.md)                   | KSQL version of the [Kafka Streams Demo Application](https://docs.confluent.io/current/streams/kafka-streams-examples/docs/index.html)
| [mysql-debezium](mysql-debezium/README.md) | end-to-end streaming ETL with KSQL for stream processing using the [Debezium Connector for MySQL](http://debezium.io/docs/connectors/mysql/)
| [pageviews](pageviews/README.md)           | automated version of the [Confluent Platform 5.0 Quickstart](https://docs.confluent.io/current/quickstart.html)
| [wikipedia](wikipedia/README.md)           | non-Docker version of the [Confluent Platform Demo](https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html)

# Running The Demos

1. Clone the repo: `git clone https://github.com/confluentinc/quickstart-demos`
2. Change directory to one of the demo subfolders
3. Start a demo with `./start.sh`
4. Stop a demo with `./stop.sh`

# Prerequisites

* [Confluent Platform 5.0](https://www.confluent.io/download/)
* Env var `CONFLUENT_HOME=/path/to/confluentplatform`
* Env var `PATH` includes `$CONFLUENT_HOME/bin`
* Each demo has its own set of prerequisites as well, documented in each demo's README
