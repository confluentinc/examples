# Overview

Produce messages to and consume messages from [Confluent Cloud](https://www.confluent.io/confluent-cloud/) using the Java Producer and Consumer, and Kafka Streams API.


# Prerequisites

* Java 1.8 or higher to run the demo application
* Maven to compile the demo application
* [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html) installed on your machine. It is provided as part of the Confluent Platform package or may be [installed separately](https://docs.confluent.io/current/cloud/cli/install.html).
* Access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/) cluster
* [Initialize](https://docs.confluent.io/current/cloud/cli/multi-cli.html#connect-ccloud-cli-to-a-cluster) your local Confluent Cloud configuration file using the `ccloud init` command, which creates the file at `$HOME/.ccloud/config`.

# Example 1: Hello World!

In this example, the producer writes Kafka data to a topic in Confluent Cloud. 
Each record has a key representing a username (e.g. `alice`) and a value of a count, formatted as json (e.g. `{"count": 0}`).
The consumer reads the same topic from Confluent Cloud and keeps a rolling sum of the counts as it processes each record.
The Kafka Streams API reads the same topic from Confluent Cloud and does a stateful sum aggregation, also a rolling sum of the counts as it processes each record.

1. Run the producer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the topic name:

	```shell
	# Build the client examples
	$ mvn clean package
	
	# Run the producer
	$ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" \
	  -Dexec.args="$HOME/.ccloud/config test1"
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
	# Build the client examples
	$ mvn clean package
	
	# Run the consumer
	$ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ConsumerExample" \
	  -Dexec.args="$HOME/.ccloud/config test1"
	```

	You should see:

	```
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

3. Run the Kafka Streams application, , passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the same topic name as used above. Verify that the consumer received all the messages:

        ```shell
        # Build the client examples
        $ mvn clean package

        # Run the consumer
        $ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.StreamsExample" \
          -Dexec.args="$HOME/.ccloud/config test1"
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
