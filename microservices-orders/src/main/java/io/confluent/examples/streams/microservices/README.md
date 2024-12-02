# Kafka Streams Microservice Examples

## Overview

This small microservices ecosystem showcases an order management workflow, such as one might find in retail and online shopping.
It is built using Kafka Streams, whereby business events that describe the order management workflow propagate through this ecosystem.
The blog post [Building a Microservices Ecosystem with Kafka Streams and KSQL](https://www.confluent.io/blog/building-a-microservices-ecosystem-with-kafka-streams-and-ksql/) outlines the approach used.

In this example, the system centers on an Orders Service which exposes a REST interface to POST and GET Orders.
Posting an Order creates an event in Kafka that is recorded in the topic `orders`.
This is picked up by different validation engines (Fraud Service, Inventory Service and Order Details Service), which validate the order in parallel, emitting a PASS or FAIL based on whether each validation succeeds.

The result of each validation is pushed through a separate topic, Order Validations, so that we retain the _single writer_ status of the Orders Service —> Orders Topic.
The results of the various validation checks are aggregated in the Validation Aggregator Service, which then moves the order to a Validated or Failed state, based on the combined result.

To allow users to GET any order, the Orders Service creates a queryable materialized view (embedded inside the Orders Service), using a state store in each instance of the service, so that any Order can be requested historically. Note also that the Orders Service can be scaled out over a number of nodes, in which case GET requests must be routed to the correct node to get a certain key. This is handled automatically using the interactive queries functionality in Kafka Streams.

The Orders Service also includes a blocking HTTP GET so that clients can read their own writes. In this way, we bridge the synchronous, blocking paradigm of a RESTful interface with the asynchronous, non-blocking processing performed server-side.

There is a simple service that sends emails and does dynamic routing.

![alt text](https://www.confluent.io/wp-content/uploads/Screenshot-2017-11-09-12.34.26.png "System Diagram")


## Getting Started

As a great introduction for developers who are just getting started with stream processing, refer to the free, self-paced [Kafka Streams tutorial](https://docs.confluent.io/current/tutorials/examples/microservices-orders/docs/index.html#tutorial-microservices-orders).
The tutorial centers on this microservices ecosystem in this GitHub repo, and it correlates streaming concepts to hands-on exercises.
You’ll learn the basics of the Kafka Streams API and common patterns to design and build event-driven applications.

As a pre-requisite, follow the [Environment Setup instructions](https://docs.confluent.io/current/tutorials/examples/microservices-orders/docs/index.html#environment-setup).

Then run the fully-working demo [end-to-end](https://docs.confluent.io/current/tutorials/examples/microservices-orders/docs/index.html#exercise-0-run-end-to-end-demo).
It runs the ecosystem and all the microservices for you including Kafka Connect, Elasticsearch, KSQL and Control Center.

To play with this ecosystem the simplest way is to run the tests and fiddle with the code (stand alone execution is only supported in branch 5.0.0+ so go there if you want stand alone or docker support). Each test boots a self-contained Kafka cluster so it's easy to play with different queries and configurations. 
The best place to start is [EndToEndTest.java](https://github.com/confluentinc/examples/blob/7.8.0-post/microservices-orders/src/test/java/io/confluent/examples/streams/microservices/EndToEndTest.java)

# Running the Examples:
* Requires Java 1.8
* mvn install -Dmaven.test.skip=true

# Outstanding Work

- Currently bare bones testing only. Should add tests using KStreamTestDriver to demonstrate how to build tests quickly. 
- Test framework needs to implement multiple Kafka instances to ensure accuracy in partitioned mode. 
- The implementation of the Order Details Service using a producer and consumer. This is useful for demo purposes, but would be better implemented as a streams job (less code!). 
- Demo embedded KSQL around the input of Inventory (which can be done without Avro support)
