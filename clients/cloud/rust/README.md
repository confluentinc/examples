# Overview

Produce messages to and consume messages from a Kafka cluster using the [rust-rdkafka client for Apache Kafka](https://github.com/fede1024/rust-rdkafka).

# Prerequisites
* [Rust client for Apache Kafka](https://github.com/fede1024/rust-rdkafka#installation) installed on your machine
* Create a local file (e.g. at `$HOME/.confluent/librdkafka.config`) with configuration parameters to connect to your Kafka cluster, which can be on your local host, [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), or any other cluster.  Follow [these detailed instructions](https://github.com/confluentinc/configuration-templates/tree/master/README.md) to properly create this file. 
* If you are running on Confluent Cloud, you must have access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud) cluster

# Example 1: Hello World!
In this example, the producer writes data to a Kafka topic.
Each record has a key representing a username (e.g. `alice`) and a value.
The consumer reads the same topic.

1. Build the producer and consumer binaries:

```bash
$ cargo build
   Compiling rust_kafka_client_example v0.1.0 (/path/to/repo/examples/clients/cloud/rust)
    Finished dev [unoptimized + debuginfo] target(s) in 2.85s
```

2. Run the producer, passing in arguments for (a) the local file with configuration parameters to connect to your Kafka cluster and (b) the topic name:

```bash
$ ./target/debug/producer --config $HOME/.confluent/librdkafka.config --topic test1
Preparing to produce record: alice 0
Preparing to produce record: alice 1
Preparing to produce record: alice 2
Preparing to produce record: alice 3
Preparing to produce record: alice 4
Preparing to produce record: alice 5
Preparing to produce record: alice 6
Preparing to produce record: alice 7
Preparing to produce record: alice 8
Successfully produced record to topic test1 partition [5] @ offset 117
Successfully produced record to topic test1 partition [5] @ offset 118
Successfully produced record to topic test1 partition [5] @ offset 119
Successfully produced record to topic test1 partition [5] @ offset 120
Successfully produced record to topic test1 partition [5] @ offset 121
Successfully produced record to topic test1 partition [5] @ offset 122
Successfully produced record to topic test1 partition [5] @ offset 123
Successfully produced record to topic test1 partition [5] @ offset 124
Successfully produced record to topic test1 partition [5] @ offset 125
```

3. Run the consumer, passing in arguments for (a) the local file with configuration parameters to connect to your Kafka cluster and (b) the same topic name as used above. Verify that the consumer received all the messages:

```bash
$ ./target/debug/consumer --config $HOME/.confluent/librdkafka.config --topic test1
Consumed record from topic test1 partition [5] @ offset 117 with key alice and value 0
Consumed record from topic test1 partition [5] @ offset 118 with key alice and value 1
Consumed record from topic test1 partition [5] @ offset 119 with key alice and value 2
Consumed record from topic test1 partition [5] @ offset 120 with key alice and value 3
Consumed record from topic test1 partition [5] @ offset 121 with key alice and value 4
Consumed record from topic test1 partition [5] @ offset 122 with key alice and value 5
Consumed record from topic test1 partition [5] @ offset 123 with key alice and value 6
Consumed record from topic test1 partition [5] @ offset 124 with key alice and value 7
Consumed record from topic test1 partition [5] @ offset 125 with key alice and value 8
```
