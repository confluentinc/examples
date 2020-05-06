# Overview

Produce messages to and consume messages from a Kafka cluster using Java interop form Clojure.

For more information, please see the [application development documentation](https://docs.confluent.io/current/api-javadoc.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud)

# Prerequisites

* Java 8 or higher (Clojure 1.10 recommends using Java 8 or Java 11)
* The [Leiningen](https://leiningen.org/#install) tool to compile and run the demos
* Create a local file (e.g. at `$HOME/.confluent/java.config`) with configuration parameters to connect to your Kafka cluster, which can be on your local host, [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), or any other cluster.  Follow [these detailed instructions](https://github.com/confluentinc/configuration-templates/tree/master/README.md) to properly create this file. 
* If you are running on Confluent Cloud, you must have access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud) cluster

# Example 1: Hello World!

In this example, the producer writes Kafka data to a topic in your Kafka cluster.
Each record has a key representing a username (e.g. `alice`) and a value of a count, formatted as json (e.g. `{"count": 0}`).
The consumer reads the same topic and keeps a rolling sum of the counts as it processes each record.

1. Run the producer, passing in arguments for (a) the local file with configuration parameters to connect to your Kafka cluster and (b) the topic name:

```shell
$ lein producer $HOME/.confluent/java.config test1
…
Producing record: alice 	{"count":0}
Producing record: alice 	{"count":1}
Producing record: alice 	{"count":2}
Producing record: alice 	{"count":3}
Producing record: alice 	{"count":4}
Produced record to topic test1 partiton [0] @ offest 0
Produced record to topic test1 partiton [0] @ offest 1
Produced record to topic test1 partiton [0] @ offest 2
Produced record to topic test1 partiton [0] @ offest 3
Produced record to topic test1 partiton [0] @ offest 4
Producing record: alice 	{"count":5}
Producing record: alice 	{"count":6}
Producing record: alice 	{"count":7}
Producing record: alice 	{"count":8}
Producing record: alice 	{"count":9}
Produced record to topic test1 partiton [0] @ offest 5
Produced record to topic test1 partiton [0] @ offest 6
Produced record to topic test1 partiton [0] @ offest 7
Produced record to topic test1 partiton [0] @ offest 8
Produced record to topic test1 partiton [0] @ offest 9
10 messages were produced to topic test1!
```

2. Run the consumer, passing in arguments for (a) the local file with configuration parameters to connect to your Kafka cluster and (b) the same topic name as used above. Verify that the consumer received all the messages:

```shell
$ lein consumer $HOME/.confluent/java.config test1
…
Waiting for message in KafkaConsumer.poll
Consumed record with key alice and value {"count":0}, and updated total count to 0
Consumed record with key alice and value {"count":1}, and updated total count to 1
Consumed record with key alice and value {"count":2}, and updated total count to 3
Consumed record with key alice and value {"count":3}, and updated total count to 6
Consumed record with key alice and value {"count":4}, and updated total count to 10
Consumed record with key alice and value {"count":5}, and updated total count to 15
Consumed record with key alice and value {"count":6}, and updated total count to 21
Consumed record with key alice and value {"count":7}, and updated total count to 28
Consumed record with key alice and value {"count":8}, and updated total count to 36
Consumed record with key alice and value {"count":9}, and updated total count to 45
Waiting for message in KafkaConsumer.poll
…
```
