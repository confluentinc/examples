.. _microservices-orders:

.. toctree:: 
    :maxdepth: 2

Developing Streaming Applications
=================================

This self-paced tutorial teaches developers basic principles of streaming applications.

========
Overview
========

This is a small microservice ecosystem built with Kafka Streams. There is a related `blog post <https://www.confluent.io/blog/building-a-microservices-ecosystem-with-kafka-streams-and-ksql/>`__  that outlines the approach used.

Note: this is demo code, not a production system and certain elements are left for further work.

.. figure:: images/microservices-demo.jpg
    :alt: image

Microservices
~~~~~~~~~~~~~

The example centers around an Orders Service which provides a REST interface to POST and GET Orders. Posting an Order creates an event in Kafka. This is picked up by three different validation engines (Fraud Service, Inventory Service, Order Details Service) which validate the order in parallel, emitting a PASS or FAIL based on whether each validation succeeds. The result of each validation is pushed through a separate topic, Order Validations, so that we retain the ‘single writer’ status of the Orders Service —> Orders Topic. The results of the various validation checks are aggregated back in the Order Service (Validation Aggregator) which then moves the order to a Validated or Failed state, based on the combined result.

To allow users to GET any order, the Orders Service creates a queryable materialized view (embedded inside the Orders Service), using a state store in each instance of the service, so any Order can be requested historically. Note also that the Orders Service can be scaled out over a number of nodes, so GET requests must be routed to the correct node to get a certain key. This is handled automatically using the Interactive Queries functionality in Kafka Streams.

The Orders Service also includes a blocking HTTP GET so that clients can read their own writes. In this way we bridge the synchronous, blocking paradigm of a Restful interface with the asynchronous, non-blocking processing performed server-side.

Finally there is a very simple email service.

All the services are client applications written in Java, and they use the Kafka Streams API.
The java source code for these microservices are in the `kafka-streams-examples repo <https://github.com/confluentinc/kafka-streams-examples/tree/5.0.1-post/src/main/java/io/confluent/examples/streams/microservices>`__.

+-------------------------------------+-----------------------------------+-----------------------+
| Service                             | Consuming From                    | Producing To          |
+=====================================+===================================+=======================+
| InventoryService                    | `orders`, `warehouse-inventory`   | `order-validations`   |
| FraudService                        | `orders`                          | `order-validations`   |
| OrderDetailsService                 | `orders`                          | `order-validations`   |
| ValidationsAggregatorService        | `order-validations`, `orders`     | `orders`              |
| EmailService                        | `orders`, `payments`, `customers` | -                     |
| OrdersService                       | -                                 | `orders`              |
| PostOrdersAndPayments               | -                                 | `payments`            |
| AddInventory                        | -                                 | `warehouse-inventory` |
+-------------------------------------+-----------------------------------+-----------------------+


End-to-end Streaming ETL
~~~~~~~~~~~~~~~~~~~~~~~~

This demo showcases an entire end-to-end streaming ETL deployment, built around the microservices described above.
It is build on the Confluent Platform, including:

* JDBC source connector: reads from a sqlite database that has a table of customers information and writes the data to a Kafka topic, using Connect transforms to add a key to each message
* Elasticsearch sink connector: pushes data from a Kafka topic to Elasticsearch
* KSQL: creates streams and tables and joins data from a STREAM of orders with a TABLE of customer data


+-------------------------------------+-----------------------+-------------------------+
| Other Clients                       | Consuming From        | Producing To            |
+=====================================+=======================+=========================+
| KSQL                                | `orders`, `customers` | KSQL streams and tables |
| JDBC source connector               | DB                    | `customers`             |
| Elasticsearch sink connector        | `orders`              | ES                      |
+-------------------------------------+-----------------------+-------------------------+


==============
Pre-requisites
==============

You will get a lot more out of this tutorial if you have first read the following:

#. Read Ben Stopford's book `Designing Event-Driven Systems <https://www.confluent.io/designing-event-driven-systems>`__.
It explains how service-based architectures and stream processing tools such as Apache Kafka® can help you build business-critical systems.
The concepts discussed in that book are the foundation for this playbook.

#. Familiarize yourself with the scenario in the `Microservices Orders Demo Application <https://github.com/confluentinc/kafka-streams-examples/tree/5.0.1-post/src/main/java/io/confluent/examples/streams/microservices>`__.

Next step is to setup your environment, depending on whether you are running |cp| locally or in Docker:


Local
-----

* `Confluent Platform 5.0 <https://www.confluent.io/download/>`__: download specifically Confluent Enterprise to use topic management, KSQL and Confluent Schema Registry integration, and streams monitoring capabilities
* Java 1.8 to run the demo application
* Maven to compile the demo application
* `Elasticsearch 5.6.5 <https://www.elastic.co/downloads/past-releases/elasticsearch-5-6-5>`__ to export data from Kafka
  * If you do not want to use Elasticsearch, comment out ``check_running_elasticsearch`` in the ``start.sh`` script
* `Kibana 5.5.2 <https://www.elastic.co/downloads/past-releases/kibana-5-5-2>`__ to visualize data
  * If you do not want to use Kibana, comment out ``check_running_kibana`` in the ``start.sh`` script

Docker
------

* Docker version 17.06.1-ce
* Docker Compose version 1.14.0 with Docker Compose file format 2.1


=====================
Run the Full Solution
=====================

We recommend that you first run the full solution to understand what a successful run looks like.
Without writing any code, you can run the end-to-end demo to showcase a customer-representative deployment of a streaming application.

Start the demo
--------------

If you are running |cp| locally, then run the full solution:

.. sourcecode:: bash

      ./start.sh

If you are running Docker, then run the full solution:

.. sourcecode:: bash

      docker-compose up -d


What You Should See
-------------------

After running the end-to-end demo:

* (Confluent Enterprise) Use Confluent Control Center to navigate to the `KSQL tab <http://localhost:9021/development/ksql/localhost%3A8088/streams>`__ to view KSQL streams and tables, and to create KSQL queries. Otherwise, run the KSQL CLI `ksql http://localhost:8088`. To get started, run the query `SELECT * FROM ORDERS;`
* (Confluent Enterprise) Use Confluent Control Center to navigate to the `Streams monitoring tab <http://localhost:9021/monitoring/streams>`__ to view the throughput and latency performance of the microservices

.. figure:: images/streams-monitoring.png
    :alt: image

* (Confluent Enterprise) Use Confluent Control Center to navigate to the `Kafka Connect tab <http://localhost:9021/management/connect/>`__ to view the JDCB source connector and Elasticsearch sink connector.
* View the Kibana dashboard at http://localhost:5601/app/kibana#/dashboard/Microservices

.. figure:: images/kibana_microservices.png
    :alt: image


========
Playbook
========



How to use the playbook
-----------------------

First run the full end-to-end working solution.
Starting at the high-level provides context for the services.

After you have run the full solution successfully, run through the playbook to learn the basic principles of streaming applications.
There are five labs in the playbook.
For each lab:

#. Read the description to understand the focus area for the lab
#. Open the file specified in each lab and fill in the missing code, identified by `TODO`
#. Compile the project and run the unit test for the code to ensure it works


Lab 1: Capture event
--------------------

Description
~~~~~~~~~~~

// YEVA: concepts

Exercise
~~~~~~~~

// YEVA: description

Instructions: implement the `TODO` lines of the file `labs/OrdersService.java <https://github.com/confluentinc/examples/tree/5.0.1-post/microservices-orders/labs/OrdersService.java>`

#. TODO 1.1: create a new `ProducerRecord` with a key specified by `bean.getId()` and value of the bean, to the orders topic whose name is specified by `ORDERS.name()`
#. TODO 1.2: produce the newly created record using the existing `producer` and pass use the `OrdersService#callback` function to send the `response` and the record key

If you get stuck, here is the `complete solution <https://github.com/confluentinc/kafka-streams-examples/blob/5.0.1-post/src/main/java/io/confluent/examples/streams/microservices/OrdersService.java>`__.

Test your code
~~~~~~~~~~~~~~

Save off the project's working solution, copy your version of the file to the main project, compile, and run the unit test.

.. sourcecode:: bash

      cp kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/OrdersService.java /tmp/.
      cp labs/OrdersService.java kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/.
      mvn clean compile -DskipTests
      mvn compile -Dtest=io.confluent.examples.streams.microservices.OrdersServiceTest test


Lab 2: Request-driven vs Event-driven
-------------------------------------

Description
~~~~~~~~~~~

Service-based architectures are often designed to be request-driven, which sends commands to other services to tell them what to do, awaits a response, or sends queries to get the resulting state.
In contrast, in an event-driven design, there an event stream is the inter-service communication which leads to less coupling and queries, enables services to cross deployment boundaries, and avoids synchronous execution.

// YEVA: add more around this

Exercise
~~~~~~~~

Write a service that validates customer orders.
Instead of using a series of synchronous calls to submit and validate orders, let the order event itself trigger the `OrderDetailsService`.
When a new order is created, it is written to the topic `orders`, from which `OrderDetailsService` has a consumer polling for new records. 

Instructions: implement the `TODO` lines of the file `labs/OrderDetailsService.java <https://github.com/confluentinc/examples/tree/5.0.1-post/microservices-orders/labs/OrderDetailsService.java>`

#. TODO 2.1: subscribe the existing `consumer` to a `Collections#singletonList` with the orders topic whose name is specified by `Topics.ORDERS.name()`
#. TODO 2.2: validate the order using `OrderDetailsService#isValid` and save the validation result to type `OrderValidationResult`
#. TODO 2.3: create a new record using `OrderDetailsService#result()` that takes the order and validation result
#. TODO 2.4: produce the newly created record using the existing `producer`

If you get stuck, here is the `complete solution <https://github.com/confluentinc/kafka-streams-examples/blob/5.0.1-post/src/main/java/io/confluent/examples/streams/microservices/OrderDetailsService.java>`__.

Test your code
~~~~~~~~~~~~~~

Save off the project's working solution, copy your version of the file to the main project, compile, and run the unit test.

.. sourcecode:: bash

      cp kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/OrderDetailsService.java /tmp/.
      cp labs/OrderDetailsService.java kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/.
      mvn clean compile -DskipTests
      mvn compile -Dtest=io.confluent.examples.streams.microservices.OrderDetailsServiceTest test


Lab 3: Enriching Streams with Joins
--------------------------------------

Description
~~~~~~~~~~~

Streams can be enriched with data from other streams or tables, through joins.
Many stream processing applications in practice are coded as streaming joins.
For example, applications backing an online shop might need to access multiple, updating database tables (e.g. sales prices, inventory, customer information) in order to enrich a new data record (e.g. customer transaction) with context information.
That is, scenarios where you need to perform table lookups at very large scale and with a low processing latency.
Here, a popular pattern is to make the information in the databases available in Kafka through so-called change data capture in combination with Kafka’s Connect API to pull in the data from the database.
Then the application using the Kafka Streams API performs very fast and efficient local joins of such tables and streams, rather than requiring the application to make a query to a remote database over the network for each record.

Exercise
~~~~~~~~

Write a service that joins streaming order information with streaming payment information and with data from a customer database.
First the payment stream needs to be rekeyed to match the same key info as the order stream, then joined together.
Then the resulting stream is joined with the customer information that was read into Kafka by a JDBC source from a customer database.

Instructions: implement the `TODO` lines of the file `labs/EmailService.java <https://github.com/confluentinc/examples/tree/5.0.1-post/microservices-orders/labs/EmailService.java>`

#. TODO 3.1: create a new `KStream` called `payments` from `payments_original`, using `KStream#selectKey` to rekey on order id specified by `payment.getOrderId()` instead of payment id
#. TODO 3.2: do a stream-table join with the customers table, which requires three arguments:
   #. the GlobalKTable for the stream-table join
   #. customer Id, specified by `order.getCustomerId()`, using a KeyValueMapper that gets the customer id from the tuple in the record's value
   #. method that computes a value for the result record, in this case `EmailTuple::setCustomer`

If you get stuck, here is the `complete solution <https://github.com/confluentinc/kafka-streams-examples/blob/5.0.1-post/src/main/java/io/confluent/examples/streams/microservices/EmailService.java>`__.


Test your code
~~~~~~~~~~~~~~

Save off the project's working solution, copy your version of the file to the main project, compile, and run the unit test.

.. sourcecode:: bash

      cp kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/EmailService.java /tmp/.
      cp labs/EmailService.java kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/.
      mvn clean compile -DskipTests
      mvn compile -Dtest=io.confluent.examples.streams.microservices.EmailServiceTest test


Lab 4: Filtering and Aggregating
--------------------------------

Description
~~~~~~~~~~~

// YEVA: 

Exercise
~~~~~~~~

// YEVA: description

Instructions: implement the `TODO` lines of the file `labs/ValidationsAggregatorService.java <https://github.com/confluentinc/examples/tree/5.0.1-post/microservices-orders/labs/ValidationsAggregatorService.java>`

#. TODO 4.1: filter this stream to include only orders in "CREATED" state, i.e., it should satisfy the predicate `OrderState.CREATED.equals(order.getState())`
#. TODO 4.2: group the records by key using `KStream#groupByKey` (required before using an aggregation operator), providing the existing Serialized instance for ORDERS
#. TODO 4.3: use an aggregation operator `KTable#reduce` to collapse the records in this stream to a single order for a given key

If you get stuck, here is the `complete solution <https://github.com/confluentinc/kafka-streams-examples/blob/5.0.1-post/src/main/java/io/confluent/examples/streams/microservices/ValidationsAggregatorService.java>`__.


Test your code
~~~~~~~~~~~~~~

Save off the project's working solution, copy your version of the file to the main project, compile, and run the unit test.

.. sourcecode:: bash

      cp kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/ValidationsAggregatorService.java /tmp/.
      cp labs/ValidationsAggregatorService.java kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/.
      mvn clean compile -DskipTests
      mvn compile -Dtest=io.confluent.examples.streams.microservices.ValidationsAggregatorServiceTest test



Lab 5: State Stores
-------------------

Description
~~~~~~~~~~~

Kafka Streams provides so-called state stores, a disk-resident hash table, held inside the API, and backed by a Kafka topic.
It can be used by stream processing applications to store and query data, which is an important capability when implementing stateful operations.

Exercise
~~~~~~~~

// YEVA: description

Instructions: implement the `TODO` lines of the file `labs/InventoryService.java <https://github.com/confluentinc/examples/tree/5.0.1-post/microservices-orders/labs/InventoryService.java>`

#. TODO 5.1: create a state store called `RESERVED_STOCK_STORE_NAME`, using `Stores#keyValueStoreBuilder` and `Stores#persistentKeyValueStore`
   #. the key Serde is derived from the topic specified by `WAREHOUSE_INVENTORY`
   #. the value Serde is derived from `Serdes.Long()` because it represents a count
#. TODO 5.2: update the reserved stock in the KeyValueStore called `reservedStocksStore`
   #. the key is the product in the order, using `OrderBean#getProduct`
   #. the value is the sum of the current reserved stock and the quantity in the order, using `OrderBean#getQuantity`

If you get stuck, here is the `complete solution <https://github.com/confluentinc/kafka-streams-examples/blob/5.0.1-post/src/main/java/io/confluent/examples/streams/microservices/InventoryService.java>`__.


Test your code
~~~~~~~~~~~~~~

Save off the project's working solution, copy your version of the file to the main project, compile, and run the unit test.

.. sourcecode:: bash

      cp kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/InventoryService.java /tmp/.
      cp labs/InventoryService.java kafka-streams-examples/src/main/java/io/confluent/examples/streams/microservices/.
      mvn clean compile -DskipTests
      mvn compile -Dtest=io.confluent.examples.streams.microservices.InventoryServiceTest test

