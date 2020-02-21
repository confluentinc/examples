# Overview

Produce messages to and consume messages from a Kafka cluster using the Java Producer and Consumer, and Kafka Streams API.


# Prerequisites

* Java 1.8 or higher to run the demo application
* Maven to compile the demo application

To run this example, download the `java.config` file from [confluentinc/configuration-templates](https://github.com/confluentinc/configuration-templates/tree/master/clients/cloud) and save it to a `$HOME/.ccloud` folder. 
Update the configuration parameters to connect to your Kafka cluster, which can be on your local host, [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), or any other cluster. If this is a Confluent Cloud cluster, you must have:

* Access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud) cluster
* Update the `java.config` file from  with the broker endpoint and api key to connect to your Confluent Cloud cluster ([how do I find those?](https://docs.confluent.io/current/cloud/using/config-client.html#librdkafka-based-c-clients?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud)).


```shell
$ cat $HOME/.ccloud/java.config
ssl.endpoint.identification.algorithm=https
sasl.mechanism=PLAIN
bootstrap.servers={{ BROKER_ENDPOINT }}
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="{{ CLUSTER_API_KEY }}" password="{{ CLUSTER_API_SECRET }}";
security.protocol=SASL_SSL
```

# Example 1: Hello World!

In this example, the producer writes Kafka data to a topic in Confluent Cloud. 
Each record has a key representing a username (e.g. `alice`) and a value of a count, formatted as json (e.g. `{"count": 0}`).
The consumer reads the same topic from Confluent Cloud and keeps a rolling sum of the counts as it processes each record.
The Kafka Streams API reads the same topic from Confluent Cloud and does a stateful sum aggregation, also a rolling sum of the counts as it processes each record.

1. Run the producer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the topic name:

	```shell
	# Compile the Java code
	$ mvn clean package
	
	# Run the producer
        # If the topic does not already exist, the code will use the Kafka Admin Client API to create the topic
	$ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" \
	  -Dexec.args="$HOME/.ccloud/java.config test1"
	```

	You should see:
	
	```shell
	...
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
	10 messages were produced to topic test1
	...
	```

2. Run the consumer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the same topic name as used above. Verify that the consumer received all the messages:

    ```shell
    # Compile the Java code
    $ mvn clean package
    
    # Run the consumer
    $ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ConsumerExample" \
      -Dexec.args="$HOME/.ccloud/java.config test1"
    ```
    
    You should see:
    
    ```shell
    ...
    Consumed record with key alice and value {"count":0}, and updated total count to 0
    Consumed record with key alice and value {"count":1}, and updated total count to 1
    Consumed record with key alice and value {"count":2}, and updated total count to 3
    Consumed record with key alice and value {"count":3}, and updated total count to 6
    Consumed record with key alice and value {"count":4}, and updated total count to 10
    Consumed record with key alice and value {"count":5}, and updated total count to 15
    Consumed record with key alice and value {"count":6}, and updated total count to 21
    Consumed record with key alice and value {"count":7}, and updated total count to 28
    Consumed record with key alice and value {"count":8}, and updated total count to 36
    Consumed record with key alice and value {"count":9}, and updated total count to 45
    ```
    
    When you are done, press `<ctrl>-c`.

3. Run the Kafka Streams application, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the same topic name as used above. Verify that the application received all the messages:

    ```shell
    # Compile the Java code
    $ mvn clean package

    # Run the Kafka streams application
    $ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.StreamsExample" \
      -Dexec.args="$HOME/.ccloud/java.config test1"
    ```

    You should see:

    ```
    ...
    [Consumed record]: alice, 0
    [Consumed record]: alice, 1
    [Consumed record]: alice, 2
    [Consumed record]: alice, 3
    [Consumed record]: alice, 4
    [Consumed record]: alice, 5
    [Consumed record]: alice, 6
    [Consumed record]: alice, 7
    [Consumed record]: alice, 8
    [Consumed record]: alice, 9
    ...
    [Running count]: alice, 0
    [Running count]: alice, 1
    [Running count]: alice, 3
    [Running count]: alice, 6
    [Running count]: alice, 10
    [Running count]: alice, 15
    [Running count]: alice, 21
    [Running count]: alice, 28
    [Running count]: alice, 36
    [Running count]: alice, 45
    ...
    ```
        
    When you are done, press `<ctrl>-c`.


# Example 2: Avro And Confluent Cloud Schema Registry

This example is similar to the previous example, except the value is formatted as Avro and integrates with the Confluent Cloud Schema Registry.
Before using Confluent Cloud Schema Registry, check its [availability and limits](https://docs.confluent.io/current/cloud/limits.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud).
Note that your VPC must be able to connect to the Confluent Cloud Schema Registry public internet endpoint.

1. As described in the [Confluent Cloud quickstart](https://docs.confluent.io/current/quickstart/cloud-quickstart/schema-registry.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), in the Confluent Cloud GUI, enable Confluent Cloud Schema Registry and create an API key and secret to connect to it.

2. Verify your Confluent Cloud Schema Registry credentials work from your host. In the output below, substitute your values for `{{ SR_API_KEY }}`, `{{ SR_API_SECRET }}`, and `{{ SR_ENDPOINT }}`.

    ```shell
    # View the list of registered subjects
    $ curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects

    # Same as above, as a single bash command to parse the values out of java-sr.config
    $ curl -u $(grep "^schema.registry.basic.auth.user.info" $HOME/.ccloud/java-sr.config | cut -d'=' -f2) $(grep "^schema.registry.url" $HOME/.ccloud/java-sr.config| cut -d'=' -f2)/subjects
    ```

3. Add the following parameters to your local Confluent Cloud configuration file (``$HOME/.ccloud/java.config``) or download the `java-sr.config` from [configuration-templates](https://github.com/confluentinc/configuration-templates/tree/master/clients/cloud). 
In the output below, substitute values for `{{ SR_API_KEY }}`, `{{ SR_API_SECRET }}`, and `{{ SR_ENDPOINT }}`.

    ```shell
    $ cat $HOME/.ccloud/java-sr.config
    ...
    basic.auth.credentials.source=USER_INFO
    schema.registry.basic.auth.user.info={{ SR_API_KEY }}:{{ SR_API_SECRET }}
    schema.registry.url=https://{{ SR_ENDPOINT }}
    ...
    ```

4. Run the Avro producer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the topic name:

    ```shell
    # Compile the Java code
    $ mvn clean package

    # Run the Avro producer
    # If the topic does not already exist, the code will use the Kafka Admin Client API to create the topic
    $ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerAvroExample" \
      -Dexec.args="$HOME/.ccloud/java-sr.config test2"
    ```

5. Run the Avro consumer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the topic name:

    ```shell
    # Compile the Java code
    $ mvn clean package
    
    # Run the Avro consumer
    $ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ConsumerAvroExample" \
      -Dexec.args="$HOME/.ccloud/java-sr.config test2"
    ```

6. Run the Avro Kafka Streams application, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the same topic name as used above. Verify that the application received all the messages:

    ```
    # Compile the Java code
    $ mvn clean package

    # Run the Avro Kafka streams application
    $ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.StreamsAvroExample" \
      -Dexec.args="$HOME/.ccloud/java-sr.config test2"
    ```

7. View the schema information registered in Confluent Cloud Schema Registry. In the output below, substitute values for `{{ SR_API_KEY }}`, `{{ SR_API_SECRET }}`, and `{{ SR_ENDPOINT }}`.

    ```
    # View the list of registered subjects
    $ curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects
    ["test2-value"]
    
    # View the schema information for subject `test2-value`
    $ curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects/test2-value/versions/1
    {"subject":"test2-value","version":1,"id":100001,"schema":"{\"name\":\"io.confluent.examples.clients.cloud.DataRecordAvro\",\"type\":\"record\",\"fields\":[{\"name\":\"count\",\"type\":\"long\"}]}"}
    ```

