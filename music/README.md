![image](../images/confluent-logo-300-2.png)

# Overview

The music demo is the KSQL version of the [Kafka Streams Demo Application](https://docs.confluent.io/current/streams/kafka-streams-examples/docs/index.html).
This isn't an exact replica of that demo because some features in Kafka Streams API are not available yet in KSQL (coming soon!).
Some of these differences are noted in the [KSQL commands](ksql.commands).

![image](images/ksql-music-demo-overview.jpg)

As with the other demos in this repo, you may run the entire demo end-to-end with `./start.sh`, and it runs on your local Confluent Platform install. Alternatively, you may follow the [step-by-step guide](live-coding-ksql-music.adoc).

Follow along with the video [Demo: Build a Streaming Application with KSQL](https://www.youtube.com/watch?v=ExEWJVjj-RA).

# Prerequisites

* [Common demo prerequisites](https://github.com/confluentinc/quickstart-demos#prerequisites)
* [Confluent Platform 5.0](https://www.confluent.io/download/)
* Java 1.8 to compile the data generator, i.e. the `KafkaMusicExampleDriver` class

# What Should I see?

After you run `./start.sh`:

* Instead of using the music demos's REST endpoints, use KSQL to inspect the data.
* If you are running Confluent Enterprise, use Control Center to view and create KSQL queries. Otherwise, run the KSQL CLI `ksql http://localhost:8088`.

