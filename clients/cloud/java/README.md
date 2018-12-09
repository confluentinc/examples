# Overview

Produce messages to and consume messages from [Confluent Cloud](https://www.confluent.io/confluent-cloud/) using the Java Producer and Consumer.


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

1. Create a topic called `test1`:

	```shell
	# Create test1 topic
	$ ccloud topic create test1
	```
	You should see
	
	```
	Topic "test1" created.
	```
	Make sure the topic is created successfully.
	
	```shell
	$ ccloud topic describe test1
	```
	
	You should see

	```
	Topic:test1	PartitionCount:1	ReplicationFactor:3	Configs:min.insync.replicas=2
	Topic: test1	Partition: 0		Leader: 0	Replicas: 0,1,2	Isr: 0,1,2
	Topic: test1	Partition: 1		Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: test1	Partition: 2		Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
	Topic: test1	Partition: 3		Leader: 0	Replicas: 0,2,1	Isr: 0,2,1
	Topic: test1	Partition: 4		Leader: 1	Replicas: 1,0,2	Isr: 1,0,2
	Topic: test1	Partition: 5		Leader: 2	Replicas: 2,1,0	Isr: 2,1,0
	Topic: test1	Partition: 6		Leader: 0	Replicas: 0,1,2	Isr: 0,1,2
	Topic: test1	Partition: 7		Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: test1	Partition: 8		Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
	Topic: test1	Partition: 9		Leader: 0	Replicas: 0,2,1	Isr: 0,2,1
	Topic: test1	Partition: 10		Leader: 1	Replicas: 1,0,2	Isr: 1,0,2
	Topic: test1	Partition: 11		Leader: 2	Replicas: 2,1,0	Isr: 2,1,0
	```

2. Run the producer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the topic name:

	```shell
	# Build the client examples
	$ mvn clean package
	
	# Run the producer
	$ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.Producer" \
	  -Dexec.args="$HOME/.ccloud/config test1"
	```

	You should see:
	
	```
        ...
        Produced record: alice	{"count":0}
        Produced record: alice	{"count":1}
        Produced record: alice	{"count":2}
        Produced record: alice	{"count":3}
        Produced record: alice	{"count":4}
        Produced record: alice	{"count":5}
        Produced record: alice	{"count":6}
        Produced record: alice	{"count":7}
        Produced record: alice	{"count":8}
        Produced record: alice	{"count":9}
        10 messages were successfully produced to topic test1
	...
	```

3. Run the consumer, passing in arguments for (a) the local file with configuration parameters to connect to your Confluent Cloud instance and (b) the same topic name as used above. Verify that the consumer received all the messages:

	```shell
	# Build the client examples
	$ mvn clean package
	
	# Run the consumer
	$ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.Consumer" \
	  -Dexec.args="$HOME/.ccloud/config test1"
	```

	You should see:

        ```
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

