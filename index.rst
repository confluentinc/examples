Demos
=====

This is a curated list of demos that showcase Apache Kafka® stream
processing on the Confluent Platform. Some demos run on local Confluent
Platform installs (download `Confluent
Platform <https://www.confluent.io/download/>`__) and others run on
Docker (install `Docker <https://docs.docker.com/install/>`__ and
`Docker Compose <https://docs.docker.com/compose/install/>`__).

Where to start
--------------

The best demo to start with is
`cp-demo <https://github.com/confluentinc/cp-demo>`__, which spins up a
Kafka event streaming application using KSQL for stream processing.
``cp-demo`` also comes with a playbook and video series, and is a great
configuration reference for Confluent Platform.

Full demo list
--------------

.. raw:: html

    <table class="data-table">
    <thead>
    <tr>
    <th>Demo</th>
    <th>Local</th>
    <th>Docker</th>
    <th>Category</th>
    <th>Description</th>
    </tr>
    </thead>
    <tbody>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/clients/README.md">Avro</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/clients/README.md">Y</a></td>
    <td>N</td>
    <td>Confluent Platform</td>
    <td>Examples of client applications using Avro and Confluent Schema Registry</td>
    </tr>
    <tr>
    <td><a href="https://github.com/confluentinc/demo-scene/blob/master/no-more-silos-mysql/demo_no-more-silos.adoc">CDC with MySQL</a></td>
    <td>N</td>
    <td><a href="https://github.com/confluentinc/demo-scene/blob/master/no-more-silos-mysql/demo_no-more-silos.adoc">Y</a></td>
    <td>Data Pipelines</td>
    <td>Self-paced steps to setup a change data capture (CDC) pipeline</td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/postgres-debezium-ksql-elasticsearch/README.md">CDC with Postgres</a></td>
    <td>N</td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/postgres-debezium-ksql-elasticsearch/README.md">Y</a></td>
    <td>Data Pipelines</td>
    <td>Enrich event stream data with CDC data from Postgres and then stream into Elasticsearch</td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/clickstream/README.md">Clickstream</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/clickstream/README.md">Y</a></td>
    <td><a href="https://docs.confluent.io/current/ksql/docs/tutorials/clickstream-docker.html#ksql-clickstream-docker" rel="nofollow">Y</a></td>
    <td>Stream Processing</td>
    <td>Automated version of the <a href="https://docs.confluent.io/current/ksql/docs/tutorials/clickstream-docker.html#ksql-clickstream-docker" rel="nofollow">KSQL Clickstream demo</a></td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/clients/cloud/README.md">Clients to Cloud</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/clients/cloud/README.md">Y</a></td>
    <td>N</td>
    <td>Confluent Cloud</td>
    <td>Examples of client applications in different programming languages connecting to <a href="https://www.confluent.io/confluent-cloud/" rel="nofollow">Confluent Cloud</a></td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/connect-streams-pipeline/README.md">Connect and Kafka Streams</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/connect-streams-pipeline/README.md">Y</a></td>
    <td>N</td>
    <td>Data Pipeline</td>
    <td>Demonstrate various ways, with and without Kafka Connect, to get data into Kafka topics and then loaded for use by the Kafka Streams API</td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/wikipedia/README.md">CP Demo</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/wikipedia/README.md">Y</a></td>
    <td><a href="https://github.com/confluentinc/cp-demo">Y</a></td>
    <td>Confluent Platform</td>
    <td><a href="https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html" rel="nofollow">Confluent Platform Demo</a> with a playbook for Kafka streaming ETL deployments</td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/cp-quickstart/README.md">CP Quickstart</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/cp-quickstart/README.md">Y</a></td>
    <td><a href="https://docs.confluent.io/current/quickstart/ce-docker-quickstart.html#ce-docker-quickstart" rel="nofollow">Y</a></td>
    <td>Confluent Platform</td>
    <td>Automated version of the <a href="https://docs.confluent.io/current/quickstart.html" rel="nofollow">Confluent Platform Quickstart</a></td>
    </tr>
    <tr>
    <td><a href="https://github.com/confluentinc/demo-scene/blob/master/gcp-pipeline/README.adoc">GCP pipeline</a></td>
    <td>N</td>
    <td><a href="https://github.com/confluentinc/demo-scene/blob/master/gcp-pipeline/README.adoc">Y</a></td>
    <td>Data Pipeline</td>
    <td>Work with <a href="https://www.confluent.io/confluent-cloud/" rel="nofollow">Confluent Cloud</a> to build cool pipelines into Google Cloud Platform (GCP)</td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/ccloud/README.md">Hybrid cloud</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/ccloud/README.md">Y</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/ccloud/README.md">Y</a></td>
    <td>Confluent Cloud</td>
    <td>End-to-end demo of a hybrid Kafka Cluster between <a href="https://www.confluent.io/confluent-cloud/" rel="nofollow">Confluent Cloud</a> and on-prem using Confluent Replicator</td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/kinesis-cloud/README.md">Kinesis to Cloud</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/kinesis-cloud/README.md">Y</a></td>
    <td>N</td>
    <td>Confluent Cloud</td>
    <td>AWS Kinesis -&gt; Confluent Cloud -&gt; Google Cloud Storage pipeline</td>
    </tr>
    <tr>
    <td><a href="https://github.com/confluentinc/demo-scene/blob/master/ksql-udf-advanced-example/README.md">KSQL UDF</a></td>
    <td><a href="https://github.com/confluentinc/demo-scene/blob/master/ksql-udf-advanced-example/README.md">Y</a></td>
    <td>N</td>
    <td>Stream Processing</td>
    <td>Advanced KSQL <a href="https://www.confluent.io/blog/build-udf-udaf-ksql-5-0" rel="nofollow">UDF</a> use case for connected cars</td>
    </tr>
    <tr>
    <td><a href="https://github.com/confluentinc/demo-scene/blob/master/ksql-workshop/">KSQL workshop</a></td>
    <td>N</td>
    <td><a href="https://github.com/confluentinc/demo-scene/blob/master/ksql-workshop/">Y</a></td>
    <td>Stream Processing</td>
    <td>showcases Kafka stream processing using KSQL and can run self-guided as a KSQL workshop</td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/microservices-orders/README.md">Microservices ecosystem</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/microservices-orders/README.md">Y</a></td>
    <td>N</td>
    <td>Stream Processing</td>
    <td><a href="https://github.com/confluentinc/kafka-streams-examples/tree/5.2.2-post/src/main/java/io/confluent/examples/streams/microservices">Microservices Orders Demo Application</a> integrated into the Confluent Platform</td>
    </tr>
    <tr>
    <td><a href="https://github.com/confluentinc/demo-scene/blob/master/mqtt-connect-connector-demo/README.md">MQTT</a></td>
    <td><a href="https://github.com/confluentinc/demo-scene/blob/master/mqtt-connect-connector-demo/README.md">Y</a></td>
    <td>N</td>
    <td>Data Pipeline</td>
    <td>Internet of Things (IoT) integration example using Apache Kafka + Kafka Connect + MQTT Connector + Sensor Data</td>
    </tr>
    <tr>
    <td><a href="https://github.com/confluentinc/cp-docker-images/tree/5.2.2-post/examples/multi-datacenter">Multi datacenter</a></td>
    <td>N</td>
    <td><a href="https://github.com/confluentinc/cp-docker-images/tree/5.2.2-post/examples/multi-datacenter">Y</a></td>
    <td>Confluent Platform</td>
    <td>This demo deploys an active-active multi-datacenter design, with two instances of Confluent Replicator copying data bidirectionally between the datacenters</td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/music/README.md">Music demo</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/music/README.md">Y</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/music/README.md">Y</a></td>
    <td>Stream Processing</td>
    <td>KSQL version of the <a href="https://docs.confluent.io/current/streams/kafka-streams-examples/docs/index.html" rel="nofollow">Kafka Streams Demo Application</a></td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/mysql-debezium/README.md">MySQL and Debezium</a></td>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/mysql-debezium/README.md">Y</a></td>
    <td><a href="https://github.com/confluentinc/demo-scene/tree/master/build-a-streaming-pipeline">Y</a></td>
    <td>Data Pipelines</td>
    <td>End-to-end streaming ETL with KSQL for stream processing using the <a href="http://debezium.io/docs/connectors/mysql/" rel="nofollow">Debezium Connector for MySQL</a></td>
    </tr>
    <tr>
    <td><a href="https://github.com/confluentinc/demo-scene/blob/master/oracle-ksql-elasticsearch/oracle-ksql-elasticsearch-docker.adoc">Oracle, KSQL, Elasticsearch</a></td>
    <td>N</td>
    <td>Y</td>
    <td>Data Pipelines</td>
    <td>Stream data from Oracle, enrich and filter with KSQL, and then stream into Elasticsearch</td>
    </tr>
    <tr>
    <td><a href="/confluentinc/examples/blob/5.3.0-post/security/README.md">Security</a></td>
    <td>Y</td>
    <td>N</td>
    <td>Confluent Platform</td>
    <td>Examples of Confluent Platform security features including ACLs for Confluent Cloud Enterprise, Role-based Access Control, and Secret Protection</td>
    </tr>
    <tr>
    <td><a href="https://github.com/confluentinc/demo-scene/tree/master/syslog">Syslog</a></td>
    <td>N</td>
    <td>Y</td>
    <td>Data Pipelines</td>
    <td>Real-time syslog processing with Apache Kafka and KSQL: filtering logs, event-driven alerting, enriching events</td>
    </tr>
    </tbody>
    </table>

Prerequisites
-------------

For local installs:

-  `Confluent Platform 5.3 <https://www.confluent.io/download/>`__
-  Env var ``CONFLUENT_HOME=/path/to/confluentplatform``
-  Env var ``PATH`` includes ``$CONFLUENT_HOME/bin``
-  Each demo has its own set of prerequisites as well, documented in
   each demo’s README

For Docker:

-  Docker version 17.06.1-ce
-  Docker Compose version 1.14.0 with Docker Compose file format 2.1

Next steps
----------

As a next step, you may want to launch just the services in Confluent
Platform with no pre-configured connectors, data sources, topics,
schemas, etc. Then you can manually configure any connectors or
applications that you want to use.

We have several resources for this purpose:

-  `cp-all-in-one <https://github.com/confluentinc/cp-docker-images/tree/5.3.0-post/examples/cp-all-in-one>`__:
   this Docker Compose file launches all services in Confluent Platform,
   and runs them in containers in your local host.
-  `cp-all-in-one-cloud <https://github.com/confluentinc/cp-docker-images/tree/5.3.0-post/examples/cp-all-in-one-cloud>`__:
   use this with your pre-configured Confluent Cloud instance. This
   Docker Compose file launches all services in Confluent Platform
   (except for the Kafka brokers), runs them in containers in your local
   host, and automatically configures them to connect to Confluent
   Cloud.
-  `Confluent CLI <https://docs.confluent.io/current/cli/index.html>`__:
   for local, non-Docker installs of Confluent Platform. This CLI
   launches all services in Confluent Platform, and runs them on your
   local host.
-  `Generate test
   data <https://www.confluent.io/blog/easy-ways-generate-test-data-kafka>`__:
   Hello world for launching Confluent Platform, plus different ways to
   generate more interesting test data for your topics

Additional documentation: `Getting
Started <https://docs.confluent.io/current/getting-started.html>`__
