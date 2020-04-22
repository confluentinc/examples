# Overview

Produce messages to and consume messages from a Kafka cluster using [Confluent CLI](https://docs.confluent.io/current/cli/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud).

*Note: The Confluent CLI is meant for development purposes only and is not suitable for a production environment*


# Prerequisites

* [Confluent Platform 5.5](https://www.confluent.io/download/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), which includes the Confluent CLI

* Create a local file (e.g. at `$HOME/.confluent/java.config`) with configuration parameters to connect to your Kafka cluster, which can be on your local host, [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), or any other cluster.  Follow [these detailed instructions](https://github.com/confluentinc/configuration-templates/tree/master/README.md) to properly create this file. 
* If you are running on Confluent Cloud, you must have access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud) cluster


# Example 1: Hello World!

In this example, the producer writes Kafka data to a topic in Confluent Cloud. 
Each record has a key representing a username (e.g. `alice`) and a value of a count, formatted as json (e.g. `{"count": 0}`).
The consumer reads the same topic from Confluent Cloud.

1. Create the topic in Confluent Cloud

```bash
$ kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` --command-config $HOME/.confluent/java.config --topic test1 --create --replication-factor 3 --partitions 6
```

2. Run the [Confluent CLI producer](https://docs.confluent.io/current/cli/command-reference/confluent-produce.html#cli-confluent-produce?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), writing messages to topic `test1`, passing in additional arguments:

* `--cloud`: write messages to the Confluent Cloud cluster specified in `$HOME/.confluent/java.config`
* `--property parse.key=true --property key.separator=,`: pass key and value, separated by a comma

```bash
$ confluent local produce test1 -- --cloud --property parse.key=true --property key.separator=,
```

At the `>` prompt, type a few messages, using a `,` as the separator between the message key and value:

```bash
alice,{"count":0}
alice,{"count":1}
alice,{"count":2}
```

When you are done, press `<ctrl>-d`.

2. Run the [Confluent CLI consumer](https://docs.confluent.io/current/cli/command-reference/confluent-consume.html#cli-confluent-consume?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), reading messages from topic `test1`, passing in additional arguments:

* `--cloud`: read messages from the Confluent Cloud cluster specified in `$HOME/.confluent/java.config`
* `--property print.key=true`: print key and value (by default, it only prints value)
* `--from-beginning`: print all messages from the beginning of the topic

```bash
$ confluent local consume test1 -- --cloud --property print.key=true --from-beginning
```

You should see the messages you typed in the previous step.

```bash
alice	{"count":0}
alice	{"count":1}
alice	{"count":2}
```

When you are done, press `<ctrl>-c`.

3. To demo the above commands, you may also run the provided script [confluent-cli-example.sh](confluent-cli-example.sh).


# Example 2: Avro And Confluent Cloud Schema Registry

This example is similar to the previous example, except the value is formatted as Avro and integrates with the Confluent Cloud Schema Registry.
Before using Confluent Cloud Schema Registry, check its [availability and limits](https://docs.confluent.io/current/cloud/limits.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud).
Note that your VPC must be able to connect to the Confluent Cloud Schema Registry public internet endpoint.

1. As described in the [Confluent Cloud quickstart](https://docs.confluent.io/current/quickstart/cloud-quickstart/schema-registry.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), in the Confluent Cloud GUI, enable Confluent Cloud Schema Registry and create an API key and secret to connect to it.

2. Verify your Confluent Cloud Schema Registry credentials work from your host. In the output below, substitute your values for `<SR API KEY>`, `<SR API SECRET>`, and `<SR ENDPOINT>`.

    ```shell
    # View the list of registered subjects
    $ curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects

    # Same as above, as a single bash command to parse the values out of $HOME/.confluent/java.config
    $ curl -u $(grep "^schema.registry.basic.auth.user.info" $HOME/.confluent/java.config | cut -d'=' -f2) $(grep "^schema.registry.url" $HOME/.confluent/java.config | cut -d'=' -f2)/subjects
    ```

3. Add the following parameters to your local Confluent Cloud configuration file (``$HOME/.confluent/java.config``). In the output below, substitute values for `<SR API KEY>`, `<SR API SECRET>`, and `<SR ENDPOINT>`.

    ```shell
    $ cat $HOME/.confluent/java.config
    ...
    basic.auth.credentials.source=USER_INFO
    schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
    schema.registry.url=https://<SR ENDPOINT>
    ...
    ```

4. Create the topic in Confluent Cloud

```bash
$ kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` --command-config $HOME/.confluent/java.config --topic test2 --create --replication-factor 3 --partitions 6
```

5. Run the [Confluent CLI producer](https://docs.confluent.io/current/cli/command-reference/confluent-produce.html#cli-confluent-produce?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), writing messages to topic `test2`, passing in additional arguments. The additional Schema Registry parameters are required to be passed in as properties instead of a properties file due to https://github.com/confluentinc/schema-registry/issues/1052.

* `--value-format avro`: use Avro data format for the value part of the message
* `--property value.schema`: define the schema 
* `--property schema.registry.url`: connect to the Confluent Cloud Schema Registry endpoint http://<SR ENDPOINT>
* `--property basic.auth.credentials.source`: specify `USER_INFO`
* `--property schema.registry.basic.auth.user.info`: <SR API KEY>:<SR API SECRET> 

```bash
$ confluent local produce test2 -- --cloud --value-format avro --property value.schema='{"type":"record","name":"myrecord","fields":[{"name":"count","type":"int"}]}' --property schema.registry.url=https://<SR ENDPOINT> --property basic.auth.credentials.source=USER_INFO --property schema.registry.basic.auth.user.info='<SR API KEY>:<SR API SECRET>'
```

At the `>` prompt, type a few messages:

```bash
{"count":0}
{"count":1}
{"count":2}
```

When you are done, press `<ctrl>-d`.

6. Run the [Confluent CLI consumer](https://docs.confluent.io/current/cli/command-reference/confluent-consume.html#cli-confluent-consume?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), reading messages from topic `test`, passing in additional arguments. The additional Schema Registry parameters are required to be passed in as properties instead of a properties file due to https://github.com/confluentinc/schema-registry/issues/1052.

* `--value-format avro`: use Avro data format for the value part of the message
* `--property schema.registry.url`: connect to the Confluent Cloud Schema Registry endpoint http://<SR ENDPOINT>
* `--property basic.auth.credentials.source`: specify `USER_INFO`
* `--property schema.registry.basic.auth.user.info`: <SR API KEY>:<SR API SECRET> 

```bash
$ confluent local consume test2 -- --cloud --value-format avro --property schema.registry.url=https://<SR ENDPOINT> --property basic.auth.credentials.source=USER_INFO --property schema.registry.basic.auth.user.info='<SR API KEY>:<SR API SECRET>' --from-beginning
```

You should see the messages you typed in the previous step.

```bash
{"count":0}
{"count":1}
{"count":2}
```

When you are done, press `<ctrl>-c`.

7. To demo the above commands, you may also run the provided script [confluent-cli-ccsr-example.sh](confluent-cli-ccsr-example.sh).
