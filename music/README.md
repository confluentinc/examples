![image](../images/confluent-logo-300-2.png)

# Overview

The music demo is the KSQL version of the [Kafka Streams Demo Application](https://docs.confluent.io/current/streams/kafka-streams-examples/docs/index.html).
This isn't an exact replica of that demo because some features in Kafka Streams API are not available yet in KSQL (coming soon!).
Some of these differences are noted in the [KSQL commands](ksql.commands). Instead of the music demos's REST endpoints,
use KSQL to inspect the data.

# Prerequisites

* [Common demo prerequisites](https://github.com/confluentinc/quickstart-demos#prerequisites)
* [Confluent Platform 4.1](https://www.confluent.io/download/)
* Java 1.8 to compile the data generator, i.e. the `KafkaMusicExampleDriver` class

# What Should I see?

After you run `./start.sh`:

* Run `ksql http://localhost:8088` to view and create queries, or open your browser and navigate to the KSQL UI at http://localhost:8088
