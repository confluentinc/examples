# Overview

Produce messages to and consume messages from [Confluent Cloud](https://www.confluent.io/confluent-cloud/) using [Confluent Python Client for Apache Kafka](https://github.com/confluentinc/confluent-kafka-python).


# Prerequisites

* [Confluent's Python Client for Apache Kafka](https://github.com/confluentinc/confluent-kafka-python) installed on your machine. Check that you are using version 1.0.0 or higher (e.g., `pip show confluent-kafka`).
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
Producing record: alice 	 {"count": 0}
Producing record: alice 	 {"count": 1}
Producing record: alice 	 {"count": 2}
Producing record: alice 	 {"count": 3}
Producing record: alice 	 {"count": 4}
Producing record: alice 	 {"count": 5}
Producing record: alice 	 {"count": 6}
Producing record: alice 	 {"count": 7}
Producing record: alice 	 {"count": 8}
Producing record: alice 	 {"count": 9}
Produced record to topic test1 partition [0] @ offset 0
Produced record to topic test1 partition [0] @ offset 1
Produced record to topic test1 partition [0] @ offset 2
Produced record to topic test1 partition [0] @ offset 3
Produced record to topic test1 partition [0] @ offset 4
Produced record to topic test1 partition [0] @ offset 5
Produced record to topic test1 partition [0] @ offset 6
Produced record to topic test1 partition [0] @ offset 7
Produced record to topic test1 partition [0] @ offset 8
Produced record to topic test1 partition [0] @ offset 9
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


# Example 2: Avro And Confluent Cloud Schema Registry

This example is similar to the previous example, except the key and value are formatted as Avro and integrates with the Confluent Cloud Schema Registry.
Before using Confluent Cloud Schema Registry, check its [availability and limits](https://docs.confluent.io/current/cloud/limits.html).
Note that your VPC must be able to connect to the Confluent Cloud Schema Registry public internet endpoint.

1. As described in the [Confluent Cloud quickstart](https://docs.confluent.io/current/quickstart/cloud-quickstart.html), in the Confluent Cloud GUI, enable Confluent Cloud Schema Registry and create an API key and secret to connect to it.

2. Verify your Confluent Cloud Schema Registry credentials work from your host. In the output below, substitute your values for `<SR API KEY>`, `<SR API SECRET>`, and `<SR ENDPOINT>`.

    ```shell
    # View the list of registered subjects
    $ curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects
    ```

3. Add the following parameters to your local Confluent Cloud configuration file (``~/.ccloud/example.config``). In the output below, substitute values for `<SR API KEY>`, `<SR API SECRET>`, and `<SR ENDPOINT>`.

    ```shell
    $ cat ~/.ccloud/example.config
    ...
    basic.auth.credentials.source=USER_INFO
    schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
    schema.registry.url=https://<SR ENDPOINT>
    ...
    ```

4. Create the topic in Confluent Cloud

```bash
$ kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" ~/.ccloud/example.config | tail -1` --command-config ~/.ccloud/example.config --topic test2 --create --replication-factor 3 --partitions 12
```

5. Run the Avro producer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the topic name:

```bash
$ ./producer_ccsr.py -f ~/.ccloud/example.config -t test2
Producing Avro record: alice	0
Producing Avro record: alice	1
Producing Avro record: alice	2
Producing Avro record: alice	3
Producing Avro record: alice	4
Producing Avro record: alice	5
Producing Avro record: alice	6
Producing Avro record: alice	7
Producing Avro record: alice	8
Producing Avro record: alice	9
Produced record to topic test2 partition [0] @ offset 0
Produced record to topic test2 partition [0] @ offset 1
Produced record to topic test2 partition [0] @ offset 2
Produced record to topic test2 partition [0] @ offset 3
Produced record to topic test2 partition [0] @ offset 4
Produced record to topic test2 partition [0] @ offset 5
Produced record to topic test2 partition [0] @ offset 6
Produced record to topic test2 partition [0] @ offset 7
Produced record to topic test2 partition [0] @ offset 8
Produced record to topic test2 partition [0] @ offset 9
10 messages were produced to topic test2!
```

6. Run the Avro consumer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the same topic name as used above. Verify that the consumer received all the messages:

```bash
$ ./consumer_ccsr.py -f ~/.ccloud/example.config -t test2
...
Waiting for message or event/error in poll()
Consumed record with key alice and value 0,                       and updated total count to 0
Consumed record with key alice and value 1,                       and updated total count to 1
Consumed record with key alice and value 2,                       and updated total count to 3
Consumed record with key alice and value 3,                       and updated total count to 6
Consumed record with key alice and value 4,                       and updated total count to 10
Consumed record with key alice and value 5,                       and updated total count to 15
Consumed record with key alice and value 6,                       and updated total count to 21
Consumed record with key alice and value 7,                       and updated total count to 28
Consumed record with key alice and value 8,                       and updated total count to 36
Consumed record with key alice and value 9,                       and updated total count to 45
...
```

7. View the schema information registered in Confluent Cloud Schema Registry. In the output below, substitute values for `<SR API KEY>`, `<SR API SECRET>`, and `<SR ENDPOINT>`.

    ```
    # View the list of registered subjects
    $ curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects
    ["test2-value"]

    # View the schema information for subject `test2-value`
    $ curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects/test2-value/versions/1
    {"subject":"test2-value","version":1,"id":100001,"schema":"{\"name\":\"io.confluent.examples.clients.cloud.DataRecordAvro\",\"type\":\"record\",\"fields\":[{\"name\":\"count\",\"type\":\"long\"}]}"}
    ```
