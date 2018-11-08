![image](../images/confluent-logo-300-2.png)

# Overview

This demo is based on the [Microservices Orders Demo Application](https://github.com/confluentinc/kafka-streams-examples/tree/5.0.x/src/main/java/io/confluent/examples/streams/microservices).
Please familiarize yourself with that scenario so that you can better interpret the demo here.  

This demo augments that Microservices Orders scenario by fully integrating it into streaming ETL built on Confluent Platform:

* [JDBC source connector](connector_jdbc_customers.config): reads from a sqlite database that has a table of customers information and writes the data to a Kafka topic, using Connect transforms to add a key to each message
* [Elasticsearch sink connector](connector_elasticsearch.config): pushes data from a Kafka topic to Elasticsearch
* [KSQL](ksql.commands): creates streams and tables and joins data from a STREAM of orders with a TABLE of customer data

![image](docs/images/microservices-demo.jpg)

# Prerequisites

## Local

As with the other demos in this repo, you may run the entire demo end-to-end with `./start.sh`, and it runs on your local Confluent Platform install.  This requires the following:

* [Common demo prerequisites](https://github.com/confluentinc/examples#prerequisites)
* [Confluent Platform 5.0](https://www.confluent.io/download/): download specifically Confluent Enterprise to use topic management, KSQL and Confluent Schema Registry integration, and streams monitoring capabilities
* Java 1.8 to run the demo application
* Maven to compile the demo application
* [Elasticsearch 5.6.5](https://www.elastic.co/downloads/past-releases/elasticsearch-5-6-5) to export data from Kafka
  * If you do not want to use Elasticsearch, comment out ``check_running_elasticsearch`` in the ``start.sh`` script
* [Kibana 5.5.2](https://www.elastic.co/downloads/past-releases/kibana-5-5-2) to visualize data
  * If you do not want to use Kibana, comment out ``check_running_kibana`` in the ``start.sh`` script

## Docker

This requires the following:

* Docker version 17.06.1-ce
* Docker Compose version 1.14.0 with Docker Compose file format 2.1

# Dataflow

Here is a description of which microservices and clients are producing to and reading from which topics (excludes internal topics).

## Microservices

| Service                             | Consuming From                    | Producing To          |
| ----------------------------------- | --------------------------------- | --------------------- |
| InventoryService                    | `orders`, `warehouse-inventory`   | `order-validations`   |
| FraudService                        | `orders`                          | `order-validations`   |
| OrderDetailsService                 | `orders`                          | `order-validations`   |
| ValidationsAggregatorService        | `order-validations`, `orders`     | `orders`              |
| EmailService                        | `orders`, `payments`, `customers` | -                     |

## Other clients

| Other Clients                       | Consuming From        | Producing To            |
| ----------------------------------- | --------------------- | ----------------------- |
| OrdersService                       | -                     | `orders`                |
| PostOrdersAndPayments               | -                     | `payments`              |
| AddInventory                        | -                     | `warehouse-inventory`   |
| KSQL                                | `orders`, `customers` | KSQL streams and tables |
| JDBC source connector               | DB                    | `customers`             |
| Elasticsearch sink connector        | `orders`              | ES                      |


# Running the Demo

Local install:

```bash
./start.sh
```

Docker:

```bash
docker-compose up -d
```

After starting the demo:

* (Confluent Enterprise) Use Confluent Control Center to navigate to the [KSQL tab](http://localhost:9021/development/ksql/localhost%3A8088/streams) to view KSQL streams and tables, and to create KSQL queries. Otherwise, run the KSQL CLI `ksql http://localhost:8088`. To get started, run the query `SELECT * FROM ORDERS;`
* (Confluent Enterprise) Use Confluent Control Center to navigate to the [Streams monitoring tab](http://localhost:9021/monitoring/streams) to view the throughput and latency performance of the microservices

![image](docs/images/streams-monitoring.png)

* (Confluent Enterprise) Use Confluent Control Center to navigate to the [Kafka Connect tab](http://localhost:9021/management/connect/) to view the JDCB source connector and Elasticsearch sink connector.
* View the Kibana dashboard at http://localhost:5601/app/kibana#/dashboard/Microservices

![image](docs/images/kibana_microservices.png)
