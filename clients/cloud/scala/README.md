# Scala Producer and Consumer for Confluent Cloud

This directory includes projects demonstrating how to use the Scala producer and consumer with Confluent Cloud.

For more information, please see the [application development documentation](https://docs.confluent.io/current/api-javadoc.html)


# Quickstart

Before running the examples, **you should setup the Confluent Cloud CLI** by running the [quickstart](https://docs.confluent.io/current/quickstart/cloud-quickstart.html#cloud-quickstart).


1. Create a topic called `testtopic`:

	```shell
	# Create page_visits topic
	$ ccloud topic create testtopic
	```
	You should see
	
	```
	Topic "testtopic" created.
	```
	Make sure the topic is created successfully.
	
	```shell
	$ ccloud topic describe testtopic
	```
	
	You should see

	```
	Topic: testtopic	PartitionCount:1	ReplicationFactor:3	Configs:min.insync.replicas=2
	Topic: testtopic	Partition: 0	Leader: 0	Replicas: 0,1,2	Isr: 0,1,2
	Topic: testtopic	Partition: 1	Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: testtopic	Partition: 2	Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
	Topic: testtopic	Partition: 3	Leader: 0	Replicas: 0,2,1	Isr: 0,2,1
	Topic: testtopic	Partition: 4	Leader: 1	Replicas: 1,0,2	Isr: 1,0,2
	Topic: testtopic	Partition: 5	Leader: 2	Replicas: 2,1,0	Isr: 2,1,0
	Topic: testtopic	Partition: 6	Leader: 0	Replicas: 0,1,2	Isr: 0,1,2
	Topic: testtopic	Partition: 7	Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: testtopic	Partition: 8	Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
	Topic: testtopic	Partition: 9	Leader: 0	Replicas: 0,2,1	Isr: 0,2,1
	Topic: testtopic	Partition: 10	Leader: 1	Replicas: 1,0,2	Isr: 1,0,2
	Topic: testtopic	Partition: 11	Leader: 2	Replicas: 2,1,0	Isr: 2,1,0
	```

1. Now we can turn our attention to the client examples in this directory.

	1. First run the example producer to publish 10 data records to Confluent Cloud.

		```shell
		# Build the client examples
		$ sbt clean 
		
		# Run the consumer
		$ sbt run 
		```
		You should see
		
		```
		<snipped>
		
		Multiple main classes detected, select one to run:
        
         [1] io.confluent.examples.clients.scala.Consumer
         [2] io.confluent.examples.clients.scala.Producer
		....
		<snipped>
		```
		Enter 1 to start the consumer

	1. Then, in a new window run the Kafka producer application to write records we  to the Kafka cluster, you should see these appear in the consumer window.

		```shell
		$ sbt run 
        		
        You should see
        		
        		```
        		<snipped>
        		
        		Multiple main classes detected, select one to run:
                
                 [1] io.confluent.examples.clients.scala.Consumer
                 [2] io.confluent.examples.clients.scala.Producer
        		....
        		<snipped>
        		```
        		Enter 1 to start the producer

		```
		
		In the consumer window you should see:
		```
		Received message: (key1, val1) at offset 71
        Received message: (key1, val2) at offset 72
        Received message: (key1, val3) at offset 73
        Received message: (key1, val4) at offset 74
        Received message: (key1, val5) at offset 75
        Received message: (key1, val6) at offset 76
        Received message: (key1, val7) at offset 77
        Received message: (key1, val8) at offset 78
        Received message: (key1, val9) at offset 79
        Received message: (key1, val10) at offset 80

```
		Hit Ctrl+C to stop.
