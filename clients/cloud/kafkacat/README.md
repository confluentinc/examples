# Overview

Produce messages to and consume messages from [Confluent Cloud](https://www.confluent.io/confluent-cloud/) using [kafkacat](https://github.com/edenhill/kafkacat).


# Prerequisites

* [kafkacat](https://github.com/edenhill/kafkacat) installed on your machine.  You must [build](https://github.com/edenhill/kafkacat#build) `kafkacat` from the latest master branch to get the `-F` functionality that makes it easy to pass in the configuration to your Confluent Cloud configuration file.
* [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html) installed on your machine. It is provided as part of the Confluent Platform package or may be [installed separately](https://docs.confluent.io/current/cloud/cli/install.html).
* Access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/) cluster
* [Initialize](https://docs.confluent.io/current/cloud/cli/multi-cli.html#connect-ccloud-cli-to-a-cluster) your local Confluent Cloud configuration file using the `ccloud init` command, which creates the file at `$HOME/.ccloud/config`.


# Example 1: Hello World!

In this example, the producer writes Kafka data to a topic in Confluent Cloud. 
Each record has a key representing a username (e.g. `alice`) and a value of a count, formatted as json (e.g. `{"count": 0}`).
The consumer reads the same topic from Confluent Cloud.

1. Create the topic in Confluent Cloud

```bash
$ ccloud topic create test1
```

2. Run `kafkacat`, writing messages to topic `test1`, passing in additional arguments:

* `-F $HOME/.ccloud/config`: configuration file for connecting to the Confluent Cloud cluster
* `-K ,`: pass key and value, separated by a comma

```bash
$ kafkacat -F $HOME/.ccloud/config -K , -P -t test1
```

Type a few messages, using a `,` as the separator between the message key and value:

```bash
alice,{"count":0}
alice,{"count":1}
alice,{"count":2}
```

When you are done, press `<ctrl>-d`.

2. Run `kafkacat` again, reading messages from topic `test`, passing in additional arguments:

* `-F $HOME/.ccloud/config`: configuration file for connecting to the Confluent Cloud cluster
* `-K ,`: pass key and value, separated by a comma
* `-e`: exit successfully when last message received

```bash
$ kafkacat -F $HOME/.ccloud/config -K , -C -t test1 -e
```

You should see the messages you typed in the previous step.

```bash
% Reading configuration from file $HOME/.ccloud/config
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
