# Overview

Produce messages to and consume messages from [Confluent Cloud](https://www.confluent.io/confluent-cloud/) using [Confluent Python Client for Apache Kafka](https://github.com/confluentinc/confluent-kafka-python).


# Prerequisites

* [Confluent's Python Client for Apache Kafka](https://github.com/confluentinc/confluent-kafka-python) installed on your machine. Check that you are using version 1.0 or higher (e.g., `pip show confluent-kafka`).
* Access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/) cluster
* Local file with configuration parameters to connect to your Confluent Cloud instance ([how do I find those?](https://docs.confluent.io/current/cloud/using/config-client.html#librdkafka-based-c-clients)). Format the file as follows:


```bash
$ cat ~/.ccloud/example.config
bootstrap.servers=<broker-1,broker-2,broker-3>
sasl.username=<api-key-id>
sasl.password=<secret-access-key>
```

# Example 1: Hello World!

In this example, the producer writes Kafka data to a topic in Confluent Cloud. 
Each record has a key representing a username (e.g. `alice`) and a value of a count, formatted as json (e.g. `{"count": 0}`).
The consumer reads the same topic from Confluent Cloud and keeps a rolling sum of the counts as it processes each record.

1. Run the producer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the topic name:

```bash
$ ./producer.py -f ~/.ccloud/example.config -t test1
Preparing to produce record: alice 	 {"count": 0}
Preparing to produce record: alice 	 {"count": 1}
Preparing to produce record: alice 	 {"count": 2}
Preparing to produce record: alice 	 {"count": 3}
Preparing to produce record: alice 	 {"count": 4}
Preparing to produce record: alice 	 {"count": 5}
Preparing to produce record: alice 	 {"count": 6}
Preparing to produce record: alice 	 {"count": 7}
Preparing to produce record: alice 	 {"count": 8}
Preparing to produce record: alice 	 {"count": 9}
Successfully produced record to topic test1 partition [0] @ offset 0
Successfully produced record to topic test1 partition [0] @ offset 1
Successfully produced record to topic test1 partition [0] @ offset 2
Successfully produced record to topic test1 partition [0] @ offset 3
Successfully produced record to topic test1 partition [0] @ offset 4
Successfully produced record to topic test1 partition [0] @ offset 5
Successfully produced record to topic test1 partition [0] @ offset 6
Successfully produced record to topic test1 partition [0] @ offset 7
Successfully produced record to topic test1 partition [0] @ offset 8
Successfully produced record to topic test1 partition [0] @ offset 9
10 messages were produced to topic test1!
```

2. Run the consumer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the same topic name as used above. Verify that the consumer received all the messages:

```bash
$ ./consumer.py -f ~/.ccloud/example.config -t test1
...
Waiting for message or event/error in poll()
Consumed record with key alice and value {"count": 0}, and updated total count to 0
Consumed record with key alice and value {"count": 1}, and updated total count to 1
Consumed record with key alice and value {"count": 2}, and updated total count to 3
Consumed record with key alice and value {"count": 3}, and updated total count to 6
Consumed record with key alice and value {"count": 4}, and updated total count to 10
Consumed record with key alice and value {"count": 5}, and updated total count to 15
Consumed record with key alice and value {"count": 6}, and updated total count to 21
Consumed record with key alice and value {"count": 7}, and updated total count to 28
Consumed record with key alice and value {"count": 8}, and updated total count to 36
Consumed record with key alice and value {"count": 9}, and updated total count to 45
Waiting for message or event/error in poll()
...
```
