![image](images/confluent-logo-300-2.png)

* [Demos](#demos)
* [Build Your Own](#build-your-own)
* [Prerequisities](#prerequisites)


# Demos

This is a curated list of demos that showcase Apache Kafka® event stream processing on the Confluent Platform, an event stream processing platform that enables you to process, organize, and manage massive amounts of streaming data across cloud, on-prem, and serverless deployments.

<p align="center">
<a href="http://www.youtube.com/watch?v=muQBd6gry0U" target="_blank"><img src="images/examples-video-thumbnail.jpg" width="360" height="270" border="10" /></a>
</p>

## Where to start

The best demo to start with is [cp-demo](https://github.com/confluentinc/cp-demo) which spins up a Kafka event streaming application using KSQL for stream processing, with many security features enabled, in an end-to-end streaming ETL pipeline with a source connector pulling from live data and a sink connector connecting to Elasticsearch and Kibana for visualizations.
`cp-demo` also comes with a tutorial and is a great configuration reference for Confluent Platform.

<p align="center"><img src="https://raw.githubusercontent.com/confluentinc/cp-demo/5.4.1-post/docs/images/cp-demo-overview.jpg" width="600"></p>

## Full demo list

* [Confluent Cloud](#confluent-cloud)
* [Stream Processing](#stream-processing)
* [Data Pipelines](#data-pipelines)
* [Confluent Platform](#confluent-platform)

### Confluent Cloud

| Demo                                       | Local | Docker | Description
| ------------------------------------------ | ----- | ------ | ---------------------------------------------------------------------------
| [Beginner Cloud](ccloud/beginner-cloud/README.md) |  Y  |  N  | Fully scripted demo that shows how to interact with your Confluent Cloud cluster and set ACLs using the CLI <br><img src="clients/cloud/images/confluent-cloud.jpeg" width="400">
| [Clients to Cloud](clients/cloud/README.md)                 |   [Y](clients/cloud/README.md)   |   N    | Client applications in different programming languages connecting to [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) <br><img src="clients/cloud/images/clients-all.png" width="450">
| [Cloud ETL](cloud-etl/README.md)                 |   [Y](cloud-etl/README.md)   |   N   | Cloud ETL solution using fully-managed Confluent Cloud connectors and fully-managed KSQL <br><img src="cloud-etl/docs/images/topology.png" width="450">
| [On-Prem Kafka to Cloud](ccloud/README.md)                 |   [Y](ccloud/README.md)   |   [Y](ccloud/README.md)    | This more advanced demo showcases an on-prem Kafka cluster and [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) cluster, and data copied between them with Confluent Replicator <br><img src="ccloud/docs/images/schema-registry-local.jpg" width="450">
| [GKE to Cloud](kubernetes/replicator-gke-cc/README.md)                 |   N   |   [Y](kubernetes/replicator-gke-cc/README.md)    | Uses Google Kubernetes Engine, [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top), and [Confluent Replicator](https://www.confluent.io/confluent-replicator/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) to explore a multicloud deployment <br><img src="kubernetes/replicator-gke-cc/docs/images/operator-demo-phase-2.png" width="450">
| [GCP pipeline](https://github.com/confluentinc/demo-scene/blob/master/gcp-pipeline/README.adoc) | N | [Y](https://github.com/confluentinc/demo-scene/blob/master/gcp-pipeline/README.adoc) | Work with [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) to build cool pipelines into Google Cloud Platform (GCP) <br><img src="https://github.com/confluentinc/demo-scene/blob/master/gcp-pipeline/images/env-data-arch-01.png" width="450">


### Stream Processing

| Demo                                       | Local | Docker | Description
| ------------------------------------------ | ----- | ------ | ---------------------------------------------------------------------------
| [Clickstream](clickstream/README.md)       |   [Y](clickstream/README.md)   |   [Y](https://docs.confluent.io/current/ksql/docs/tutorials/clickstream-docker.html#ksql-clickstream-docker?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top)    | Automated version of the [KSQL clickstream demo](https://docs.confluent.io/current/ksql/docs/tutorials/clickstream-docker.html#ksql-clickstream-docker?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) <br><img src="https://docs.confluent.io/current/_images/grafana-success.png" width="450">
| [Kafka Tutorials](https://kafka-tutorials.confluent.io?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top)       |   [Y](https://kafka-tutorials.confluent.io?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top)   |   [Y](https://kafka-tutorials.confluent.io?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top)   | Collection of common event streaming use cases, with each tutorial featuring an example scenario and several complete code solutions <br><img src="https://cdn.confluent.io/wp-content/uploads/Kafka-Tutorials-350x195.jpg" width="350">
| [KSQL UDF](https://github.com/confluentinc/demo-scene/blob/master/ksql-udf-advanced-example/README.md?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) | [Y](https://github.com/confluentinc/demo-scene/blob/master/ksql-udf-advanced-example/README.md?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) | N | Advanced [KSQL User-Defined Function (UDF)](https://www.confluent.io/blog/build-udf-udaf-ksql-5-0?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) use case for connected cars <br><img src="https://www.confluent.io/wp-content/uploads/KSQL-1-350x195.png" width="350">
| [KSQL workshop](https://github.com/confluentinc/demo-scene/blob/master/ksql-workshop/)   |   N   |   [Y](https://github.com/confluentinc/demo-scene/blob/master/ksql-workshop/)    | showcases Kafka event stream processing using KSQL and can run self-guided as a KSQL workshop <br><img src="https://github.com/confluentinc/demo-scene/blob/master/ksql-workshop/images/ksql_workshop_01.png" width="450">
| [Microservices ecosystem](microservices-orders/README.md) |   [Y](microservices-orders/README.md)   |   N    | [Microservices orders Demo Application](https://github.com/confluentinc/kafka-streams-examples/tree/5.2.2-post/src/main/java/io/confluent/examples/streams/microservices) integrated into the Confluent Platform <br><img src="microservices-orders/docs/images/microservices-demo.jpg" width="450">
| [Music demo](music/README.md)                   |   [Y](music/README.md)   |   [Y](music/README.md)    | KSQL version of the [Kafka Streams Demo Application](https://docs.confluent.io/current/streams/kafka-streams-examples/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) <br><img src="music/images/ksql-music-demo-overview.jpg" width="450">


### Data Pipelines

| Demo                                       | Local | Docker | Description
| ------------------------------------------ | ----- | ------ | ---------------------------------------------------------------------------
| [CDC with MySQL](https://github.com/confluentinc/demo-scene/blob/master/no-more-silos/demo_no-more-silos.adoc) | N | [Y](https://github.com/confluentinc/demo-scene/blob/master/no-more-silos/demo_no-more-silos.adoc) | Self-paced steps to set up a change data capture (CDC) pipeline <br><img src="https://www.confluent.io/wp-content/uploads/kafka_connect-1.png" width="450">
| [CDC with Postgres](postgres-debezium-ksql-elasticsearch/README.md) |   N   |   [Y](postgres-debezium-ksql-elasticsearch/README.md)    | Enrich event stream data with CDC data from Postgres and then stream into Elasticsearch <br><img src="postgres-debezium-ksql-elasticsearch/images/ksql-debezium-es.png" width="450">
| [Clients](clients/cloud/README.md)                 |   [Y](clients/cloud/README.md)   |   N    | Client applications in different programming languages <br><img src="clients/cloud/images/clients-all.png" width="450">
| [Connect and Kafka Streams](connect-streams-pipeline/README.md) |   [Y](connect-streams-pipeline/README.md)   |   N    | Demonstrate various ways, with and without Kafka Connect, to get data into Kafka topics and then loaded for use by the Kafka Streams API <br><img src="connect-streams-pipeline/images/blog_connect_streams_diag.jpg" width="450">
| [MQTT](https://github.com/confluentinc/demo-scene/blob/master/mqtt-connect-connector-demo/README.md) | [Y](https://github.com/confluentinc/demo-scene/blob/master/mqtt-connect-connector-demo/README.md) | N | Internet of Things (IoT) integration example using Apache Kafka + Kafka Connect + MQTT Connector + Sensor Data <br><img src="https://www.confluent.io/wp-content/uploads/dwg_MQTT.svg" width="450">
| [MySQL and Debezium](mysql-debezium/README.md) |   [Y](mysql-debezium/README.md)   |   [Y](https://github.com/confluentinc/demo-scene/tree/master/build-a-streaming-pipeline) | End-to-end streaming ETL with KSQL for stream processing using the [Debezium Connector for MySQL](http://debezium.io/docs/connectors/mysql/) <br><img src="mysql-debezium/images/ksql-debezium-es.png" width="450">
| [Syslog](https://github.com/confluentinc/demo-scene/tree/master/syslog) |   N   |   Y    | Real-time syslog processing with Apache Kafka and KSQL: filtering logs, event-driven alerting, and enriching events <br><img src="https://camo.githubusercontent.com/6436ef9d9bca4eaa9d300c713fee0e4be6db8ee6/68747470733a2f2f7777772e636f6e666c75656e742e696f2f77702d636f6e74656e742f75706c6f6164732f6b73716c5f7379736c6f6730312d31303234783235382e706e67" width="450">


### Confluent Platform

| Demo                                       | Local | Docker | Description
| ------------------------------------------ | ----- | ------ | ---------------------------------------------------------------------------
| [Avro](clients/README.md)               |   [Y](clients/README.md)   |   N    | Client applications using Avro and Confluent Schema Registry <br><img src="https://www.confluent.io/wp-content/uploads/dwg_SchemaReg_howitworks.png" width="420">
| [CP Demo](https://github.com/confluentinc/cp-demo)           |   [Y](wikipedia/README.md)   |   [Y](https://github.com/confluentinc/cp-demo)    | [Confluent Platform demo](https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) (`cp-demo`) with a tutorial for Kafka event streaming ETL deployments <br><img src="https://github.com/confluentinc/cp-demo/blob/5.4.10-post/docs/images/cp-demo-overview.jpg" width="420">
| [Kubernetes](kubernetes/README.md)                 |   N   |   [Y](kubernetes/README.md)    | Demonstrations of Confluent Platform deployments using the  [Confluent Operator](https://docs.confluent.io/current/installation/operator/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) <br><img src="kubernetes/gke-base/docs/images/operator.png" width="420">
| [Multi Datacenter](multi-datacenter/README.md) | N | [Y](multi-datacenter/README.md) | Active-active multi-datacenter design with two instances of Confluent Replicator copying data bidirectionally between the datacenters <br><img src="https://docs.confluent.io/current/_images/mdc-level-1.png" width="420">
| [Multi Region Replication](multiregion/README.md) | N | [Y](multiregion/README.md) | Multi-region replication with follower fetching, observers, and replica placement<br><img src="multiregion/images/multi-region-topic-replicas-v2.png" width="420">
| [Quickstart](cp-quickstart/README.md)           |   [Y](cp-quickstart/README.md)   |   [Y](https://docs.confluent.io/current/quickstart/ce-docker-quickstart.html#ce-docker-quickstart?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top)    | Automated version of the [Confluent Platform Quickstart](https://docs.confluent.io/current/quickstart.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top) <br><img src="https://docs.confluent.io/current/_images/confluentPlatform.png" width="420">
| [Role-Based Access Control](security/rbac/README.md) |  Y  |  Y  | Role-based Access Control (RBAC) provides granular privileges for users and service accounts <img src="https://docs.confluent.io/current/_images/rbac-overview.png" width="450">
| [Secret Protection](security/secret-protection/README.adoc) |  Y  |  Y  | Secret Protection feature encrypts secrets in configuration files <br><img src="https://cdn.confluent.io/wp-content/uploads/Secret_Protection_Feature.jpg" width="400">
| [Replicator Security](replicator-security/README.md) | N | [Y](replicator-security/README.md) | Demos of various security configurations supported by Confluent Replicator and examples of how to implement them <br><img src="images/replicator-security.png" width="300">

# Build Your Own

As a next step, you may want to build your own custom demo or test environment.
We have several resources that launch just the services in Confluent Platform with no pre-configured connectors, data sources, topics, schemas, etc.
Using these as a foundation, you can then add any connectors or applications.

* [cp-all-in-one](cp-all-in-one/README.md): This Docker Compose file launches all services in Confluent Platform, and runs them in containers in your local host.
* [cp-all-in-one-community](cp-all-in-one-community/README.md): This Docker Compose file launches only the community services in Confluent Platform, and runs them in containers in your local host.
* [cp-all-in-one-cloud](cp-all-in-one-cloud/README.md): Use this with your pre-configured Confluent Cloud instance. This Docker Compose file launches all services in Confluent Platform (except for the Kafka brokers), runs them in containers in your local host, and automatically configures them to connect to Confluent Cloud.
* [Confluent CLI](https://docs.confluent.io/current/cli/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top): For local, non-Docker installs of Confluent Platform. Using this CLI, you can launch all services in Confluent Platform with just one command `confluent local start`, and they will all run on your local host.
* [Generate test data](https://www.confluent.io/blog/easy-ways-generate-test-data-kafka?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top): "Hello, World!" for launching Confluent Platform, plus different ways to generate more interesting test data for your topics

Additional documentation: [Getting Started](https://docs.confluent.io/current/getting-started.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top)


# Prerequisites

For local installs:

* Download [Confluent Platform 5.4](https://www.confluent.io/download/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.top)
* Env var `CONFLUENT_HOME=/path/to/confluentplatform`
* Env var `PATH` includes `$CONFLUENT_HOME/bin`
* Each demo has its own set of prerequisites as well, documented individually in each demo

For Docker: demos have been validated with

* [Docker](https://docs.docker.com/install/) version 17.06.1-ce
* [Docker Compose](https://docs.docker.com/compose/install/) version 1.14.0 with Docker Compose file format 2.1

