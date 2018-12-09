# Overview

Produce messages to and consume messages from [Confluent Cloud](https://www.confluent.io/confluent-cloud/) using [Confluent CLI](https://docs.confluent.io/current/cli/index.html).

*Note: The Confluent CLI is meant for development purposes only and is not suitable for a production environment*


# Prerequisites

* [Confluent CLI](https://docs.confluent.io/current/cli/installing.html) installed on your machine, version 5.1.0 or higher. It is provided as part of the [Confluent Platform](https://www.confluent.io/download/).
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

2. Run the [Confluent CLI producer](https://docs.confluent.io/current/cli/command-reference/confluent-produce.html#cli-confluent-produce), writing messages to topic `test1`, passing in additional arguments:

* `--cloud`: write messages to the Confluent Cloud cluster specified in `$HOME/.ccloud/config`
* `--property parse.key=true --property key.separator=,`: pass key and value, separated by a comma

```bash
$ confluent produce test1 --cloud --property parse.key=true --property key.separator=,
```

At the `>` prompt, type a few messages, using a `,` as the separator between the message key and value:

```bash
alice,{"count":0}
alice,{"count":1}
alice,{"count":2}
```

When you are done, press `<ctrl>-d`.

2. Run the [Confluent CLI consumer](https://docs.confluent.io/current/cli/command-reference/confluent-consume.html#cli-confluent-consume), reading messages from topic `test`, passing in additional arguments:

* `--cloud`: read messages from the Confluent Cloud cluster specified in `$HOME/.ccloud/config`
* `--property print.key=true`: print key and value (by default, it only prints value)
* `--from-beginning`: print all messages from the beginning of the topic

```bash
$ confluent consume test1 --cloud --property print.key=true --from-beginning     
```

You should see the messages you typed in the previous step.

```bash
alice	{"count":0}
alice	{"count":1}
alice	{"count":2}
```

When you are done, press `<ctrl>-c`.

3. To demo the above commands, you may also run the provided script [confluent-cli-example.sh](confluent-cli-example.sh).
