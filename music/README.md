![image](../images/confluent-logo-300-2.png)

# Overview

The music demo is the KSQL version of the [Kafka Streams Demo Application](https://docs.confluent.io/current/streams/kafka-streams-examples/docs/index.html).
This isn't an exact replica of that demo because some features in Kafka Streams API are not available yet in KSQL (coming soon!).
Some of these differences are noted in the [KSQL commands](ksql.commands). Instead of the music demos's REST endpoints,
use KSQL to inspect the data.

# Prerequisites

* [Common demo prerequisites](https://github.com/confluentinc/quickstart-demos#prerequisites)
* [Confluent Platform 5.0](https://www.confluent.io/download/)
* Java 1.8 to compile the data generator, i.e. the `KafkaMusicExampleDriver` class

# What Should I see?

After you run `./start.sh`:

* If you are running Confluent Enterprise, use Control Center to view and create KSQL queries. Otherwise, run the KSQL CLI `ksql http://localhost:8088`.
