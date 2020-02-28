# Overview

Produce messages to and consume messages from a Kafka cluster using the [ ZenDesk Ruby Client for Apache Kafka](https://github.com/zendesk/ruby-kafka).
# Prerequisites

* [Bundler](https://bundler.io/) installed on your machine. Install via `gem install bundler`
* Install gems
    ```bash
    $ cd clients/ruby
    $ bundle install
    ```
* Create a local file (e.g. at `$HOME/.confluent/librdkafka.config`) with configuration parameters to connect to your Kafka cluster, which can be on your local host, [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), or any other cluster.  Follow [these detailed instructions](https://github.com/confluentinc/configuration-templates/tree/master/README.md) to properly create this file. 
* If you are running on Confluent Cloud, you must have access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud) cluster

# Example 1: Hello World!

In this example, the producer writes Kafka data to a topic in Confluent Cloud. 
Each record has a key representing a username (e.g. `alice`) and a value of a count, formatted as json (e.g. `{"count": 0}`).
The consumer reads the same topic from Confluent Cloud and keeps a rolling sum of the counts as it processes each record.

1. Run the producer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the topic name:
    ```bash
    $ ruby producer.rb -f $HOME/.confluent/librdkafa.config --topic test1
    Created topic test1
    Producing record: alice	{"count":0}
    Producing record: alice	{"count":1}
    Producing record: alice	{"count":2}
    Producing record: alice	{"count":3}
    Producing record: alice	{"count":4}
    Producing record: alice	{"count":5}
    Producing record: alice	{"count":6}
    Producing record: alice	{"count":7}
    Producing record: alice	{"count":8}
    Producing record: alice	{"count":9}
    10 messages were successfully produced to topic test1!
    ```

2. Run the consumer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the same topic name as used above. Verify that the consumer received all the messages:
    ```bash
    $ ruby consumer.rb -f $HOME/.confluent/librdkafa.config --topic test1
    Consuming messages from test1
    Consumed record with key alice and value {"count":0}, and updated total count 0
    Consumed record with key alice and value {"count":1}, and updated total count 1
    Consumed record with key alice and value {"count":2}, and updated total count 3
    Consumed record with key alice and value {"count":3}, and updated total count 6
    Consumed record with key alice and value {"count":4}, and updated total count 10
    Consumed record with key alice and value {"count":5}, and updated total count 15
    Consumed record with key alice and value {"count":6}, and updated total count 21
    Consumed record with key alice and value {"count":7}, and updated total count 28
    Consumed record with key alice and value {"count":8}, and updated total count 36
    Consumed record with key alice and value {"count":9}, and updated total count 45
    ...
    ```
