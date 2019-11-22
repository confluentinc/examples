# Overview

Produce messages to and consume messages from [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud) using the C client [librdkafka](https://github.com/edenhill/librdkafka).


# Prerequisites

* [librdkafka](https://github.com/edenhill/librdkafka) installed on your machine, see [installation instructions](https://github.com/edenhill/librdkafka/blob/master/README.md#instructions).
* Access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud) cluster
* Local file with configuration parameters to connect to your Confluent Cloud instance ([how do I find those?](https://docs.confluent.io/current/cloud/using/config-client.html#librdkafka-based-c-clients?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud)). Format the file as follows:


# Build the example applications

From this directory, simply run make to build the `producer` and `consumer` applications.

```bash
$ make
cc   consumer.c common.c json.c -o consumer -lrdkafka -lm
cc   producer.c common.c json.c -o producer -lrdkafka -lm
```

# Create a configuration file

The configuration file must contain the bootstrap servers and
the SASL username and password, as shown in your Confluent Cloud settings.

Additional configuration properties are supported, see [CONFIGURATION.md](https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md) for the full list.

```bash
$ cat $HOME/.ccloud/example.config
bootstrap.servers=<broker-1,broker-2,broker-3>
sasl.username=<api-key-id>
sasl.password=<secret-access-key>
```

# Example 1: Hello World!

In this example, the producer writes JSON data to a topic in Confluent Cloud.
Each record has a key representing a username (e.g. `alice`) and a value of a count, formatted as json (e.g. `{"count": 0}`).
The consumer reads the same topic from Confluent Cloud and keeps a rolling sum of the counts as it processes each record.

1. Run the producer, passing in arguments for (a) the topic name, and (b) the local file with configuration parameters to connect to your Confluent Cloud instance:

```bash
$ ./producer test1 $HOME/.ccloud/example.config
Creating topic test1
Topic test1 successfully created
Producing message #0 to test1: alice={ "count": 1 }
Producing message #1 to test1: alice={ "count": 2 }
Producing message #2 to test1: alice={ "count": 3 }
Producing message #3 to test1: alice={ "count": 4 }
Producing message #4 to test1: alice={ "count": 5 }
Producing message #5 to test1: alice={ "count": 6 }
Producing message #6 to test1: alice={ "count": 7 }
Producing message #7 to test1: alice={ "count": 8 }
Producing message #8 to test1: alice={ "count": 9 }
Producing message #9 to test1: alice={ "count": 10 }
Waiting for 10 more delivery results
Message delivered to test1 [0] at offset 0 in 22.75ms: { "count": 1 }
Message delivered to test1 [0] at offset 1 in 22.77ms: { "count": 2 }
Message delivered to test1 [0] at offset 2 in 22.77ms: { "count": 3 }
Message delivered to test1 [0] at offset 3 in 22.78ms: { "count": 4 }
Message delivered to test1 [0] at offset 4 in 22.78ms: { "count": 5 }
Message delivered to test1 [0] at offset 5 in 22.78ms: { "count": 6 }
Message delivered to test1 [0] at offset 6 in 22.78ms: { "count": 7 }
Message delivered to test1 [0] at offset 7 in 22.79ms: { "count": 8 }
Message delivered to test1 [0] at offset 8 in 22.80ms: { "count": 9 }
Message delivered to test1 [0] at offset 9 in 22.81ms: { "count": 10 }
10/10 messages delivered
```


2. Run the consumer, passing in arguments for (a) the same topic name as used above, (b) the local file with configuration parameters to connect to your Confluent Cloud instance. Verify that the consumer received all the messages, then press Ctrl-C to exit.

```bash
$ ./consumer test1 $HOME/.ccloud/example.config
Subscribing to test1, waiting for assignment and messages...
Press Ctrl-C to exit.
Received message on test1 [0] at offset 0: { "count": 1 }
User alice sum 1
Received message on test1 [0] at offset 1: { "count": 2 }
User alice sum 3
Received message on test1 [0] at offset 2: { "count": 3 }
User alice sum 6
Received message on test1 [0] at offset 3: { "count": 4 }
User alice sum 10
Received message on test1 [0] at offset 4: { "count": 5 }
User alice sum 15
Received message on test1 [0] at offset 5: { "count": 6 }
User alice sum 21
Received message on test1 [0] at offset 6: { "count": 7 }
User alice sum 28
Received message on test1 [0] at offset 7: { "count": 8 }
User alice sum 36
Received message on test1 [0] at offset 8: { "count": 9 }
User alice sum 45
Received message on test1 [0] at offset 9: { "count": 10 }
User alice sum 55
```
