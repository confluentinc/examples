# Overview

Produce messages to and consume messages from a Kafka cluster using [kafkacat](https://github.com/edenhill/kafkacat).


# Prerequisites

* [kafkacat](https://github.com/edenhill/kafkacat) installed on your machine.  You must [build](https://github.com/edenhill/kafkacat#build) `kafkacat` from the latest master branch to get the `-F` functionality that makes it easy to pass in the configuration to your Confluent Cloud configuration file.
* Create a local file (e.g. at `$HOME/.confluent/java.config`) with configuration parameters to connect to your Kafka cluster, which can be on your local host, [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), or any other cluster.  Follow [these detailed instructions](https://github.com/confluentinc/configuration-templates/tree/master/README.md) to properly create this file. 
* If you are running on Confluent Cloud, you must have access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud) cluster

# Example 1: Hello World!

In this example, the producer writes Kafka data to a topic in your Kafka cluster. 
Each record has a key representing a username (e.g. `alice`) and a value of a count, formatted as json (e.g. `{"count": 0}`).
The consumer reads the same topic.

1. Create the topic in Confluent Cloud

```bash
$ kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` --command-config $HOME/.confluent/java.config --topic test1 --create --replication-factor 3 --partitions 6
```

2. Run `kafkacat`, writing messages to topic `test1`, passing in additional arguments:

* `-F $HOME/.confluent/java.config`: configuration file for connecting to the Confluent Cloud cluster
* `-K ,`: pass key and value, separated by a comma

```bash
$ kafkacat -F $HOME/.confluent/java.config -K , -P -t test1
```

Type a few messages, using a `,` as the separator between the message key and value:

```bash
alice,{"count":0}
alice,{"count":1}
alice,{"count":2}
```

When you are done, press `<ctrl>-d`.

2. Run `kafkacat` again, reading messages from topic `test`, passing in additional arguments:

* `-F $HOME/.confluent/java.config`: configuration file for connecting to the Confluent Cloud cluster
* `-K ,`: pass key and value, separated by a comma
* `-e`: exit successfully when last message received

```bash
$ kafkacat -F $HOME/.confluent/java.config -K , -C -t test1 -e
```

You should see the messages you typed in the previous step.

```bash
% Reading configuration from file $HOME/.confluent/java.config
% Reached end of topic test1 [3] at offset 0
alice,{"count":0}
alice,{"count":1}
alice,{"count":2}
% Reached end of topic test1 [7] at offset 0
% Reached end of topic test1 [4] at offset 0
% Reached end of topic test1 [6] at offset 0
% Reached end of topic test1 [5] at offset 0
% Reached end of topic test1 [1] at offset 0
% Reached end of topic test1 [2] at offset 0
% Reached end of topic test1 [9] at offset 0
% Reached end of topic test1 [10] at offset 0
% Reached end of topic test1 [0] at offset 0
% Reached end of topic test1 [8] at offset 0
% Reached end of topic test1 [11] at offset 3: exiting
```

3. To demo the above commands, you may also run the provided script [kafkacat-example.sh](kafkacat-example.sh).
