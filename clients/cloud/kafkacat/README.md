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

* `-F $HOME/.ccloud/config`: write messages to the Confluent Cloud cluster specified in `$HOME/.ccloud/config`
* `-K ,`: pass key and value, separated by a comma

```bash
$ kafkacat -F /Users/yeva/.ccloud/config -K , -P -t test1
```

At the `>` prompt, type a few messages, using a `,` as the separator between the message key and value:

```bash
alice,{"count":0}
alice,{"count":1}
alice,{"count":2}
```

When you are done, press `<ctrl>-d`.

2. Run `kafkacat` again, reading messages from topic `test`, passing in additional arguments:

* `-F $HOME/.ccloud/config`: write messages to the Confluent Cloud cluster specified in `$HOME/.ccloud/config`
* `-K ,`: pass key and value, separated by a comma

```bash
$ kafkacat -F /Users/yeva/.ccloud/config -K , -C -t test1
```

You should see the messages you typed in the previous step.

```bash
% Reading configuration from file /Users/yeva/.ccloud/config
% Reached end of topic test2 [3] at offset 0
alice,{"count":0}
alice,{"count":1}
alice,{"count":2}
% Reached end of topic test2 [7] at offset 0
% Reached end of topic test2 [4] at offset 0
% Reached end of topic test2 [6] at offset 0
% Reached end of topic test2 [5] at offset 0
% Reached end of topic test2 [1] at offset 0
% Reached end of topic test2 [2] at offset 0
% Reached end of topic test2 [9] at offset 0
% Reached end of topic test2 [10] at offset 0
% Reached end of topic test2 [0] at offset 0
% Reached end of topic test2 [8] at offset 0
% Reached end of topic test2 [11] at offset 3
```

When you are done, press `<ctrl>-c`.

3. To demo the above commands, you may also run the provided script [kafkacat-example.sh](kafkacat-example.sh).
