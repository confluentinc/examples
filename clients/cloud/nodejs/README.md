# Overview

Produce messages to and consume messages from [Confluent Cloud](https://www.confluent.io/confluent-cloud/) using the [ node-rdkafka client for Apache Kafka](https://github.com/Blizzard/node-rdkafka).

# Prerequisites

* [Node.js](https://nodejs.org/) version 8.6 or higher installed on your machine.
* [OpenSSL](https://www.openssl.org) version 1.0.2.
* Access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/) cluster
* Local file with configuration parameters to connect to your Confluent Cloud instance ([how do I find those?](https://docs.confluent.io/current/cloud/using/config-client.html#librdkafka-based-c-clients)). Format the file as follows:
```bash
$ cat ~/.ccloud/example.config
bootstrap.servers=<broker-1,broker-2,broker-3>
sasl.username=<api-key-id>
sasl.password=<secret-access-key>
```
* Install npm dependencies.
```bash
$ cd clients/nodejs
$ npm install
```
_Note: Users of macOS 10.13 (High Sierra) and above should heed [node-rdkafka's additional configuration instructions related to OpenSSL](https://github.com/Blizzard/node-rdkafka/blob/56c31c4e81f2a042666160338ad65dc4f8f2d87e/README.md#mac-os-high-sierra--mojave) before running `npm install`._


# Example 1: Hello World!

In this example, the producer writes Kafka data to a topic in Confluent Cloud. 
Each record has a key representing a username (e.g. `alice`) and a value of a count, formatted as json (e.g. `{"count": 0}`).
The consumer reads the same topic from Confluent Cloud and keeps a rolling sum of the counts as it processes each record.

1. Run the producer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the topic name:
```bash
$ node producer.js -f ~/.ccloud/example.config -t test1
Created topic test1
Producing record alice	{"count":0}
Producing record alice	{"count":1}
Producing record alice	{"count":2}
Producing record alice	{"count":3}
Producing record alice	{"count":4}
Producing record alice	{"count":5}
Producing record alice	{"count":6}
Producing record alice	{"count":7}
Producing record alice	{"count":8}
Producing record alice	{"count":9}
Successfully produced record to topic "test1" partition 0 {"count":0}
Successfully produced record to topic "test1" partition 0 {"count":1}
Successfully produced record to topic "test1" partition 0 {"count":2}
Successfully produced record to topic "test1" partition 0 {"count":3}
Successfully produced record to topic "test1" partition 0 {"count":4}
Successfully produced record to topic "test1" partition 0 {"count":5}
Successfully produced record to topic "test1" partition 0 {"count":6}
Successfully produced record to topic "test1" partition 0 {"count":7}
Successfully produced record to topic "test1" partition 0 {"count":8}
Successfully produced record to topic "test1" partition 0 {"count":9}
```

2. Run the consumer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the same topic name as used above. Verify that the consumer received all the messages:
```bash
$ node consumer.js -f ~/.ccloud/example.config -t test1
Consuming messages from test1
Consumed record with key alice and value {"count":0} of partition 0 @ offset 0. Updated total count to 1
Consumed record with key alice and value {"count":1} of partition 0 @ offset 1. Updated total count to 2
Consumed record with key alice and value {"count":2} of partition 0 @ offset 2. Updated total count to 3
Consumed record with key alice and value {"count":3} of partition 0 @ offset 3. Updated total count to 4
Consumed record with key alice and value {"count":4} of partition 0 @ offset 4. Updated total count to 5
Consumed record with key alice and value {"count":5} of partition 0 @ offset 5. Updated total count to 6
Consumed record with key alice and value {"count":6} of partition 0 @ offset 6. Updated total count to 7
Consumed record with key alice and value {"count":7} of partition 0 @ offset 7. Updated total count to 8
Consumed record with key alice and value {"count":8} of partition 0 @ offset 8. Updated total count to 9
Consumed record with key alice and value {"count":9} of partition 0 @ offset 9. Updated total count to 10
```
