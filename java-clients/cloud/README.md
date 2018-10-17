# Java Producer and Consumer for Confluent Cloud

This directory includes projects demonstrating how to use the Java producer and consumer with Confluent Cloud.

For more information, please see the [application development documentation](https://docs.confluent.io/current/api-javadoc.html)


# Quickstart

Before running the examples, **you should setup the Confluent Cloud CLI** by running the [quickstart](https://support.confluent.io/hc/en-us/articles/115003275306-Confluent-Cloud-CLI-ccloud-quick-start). 


1. Create a topic called `page_visits`:

	```shell
	# Create page_visits topic
	$ ccloud topic create page_visits
	```
	You should see
	
	```
	Topic "page_visits" created.
	```
	Make sure the topic is created successfully.
	
	```shell
	$ ccloud topic describe page_visits
	```
	
	You should see

	```
	Topic:page_visits	PartitionCount:1	ReplicationFactor:3	Configs:min.insync.replicas=2
	Topic: page_visits	Partition: 0	Leader: 0	Replicas: 0,1,2	Isr: 0,1,2
	Topic: page_visits	Partition: 1	Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: page_visits	Partition: 2	Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
	Topic: page_visits	Partition: 3	Leader: 0	Replicas: 0,2,1	Isr: 0,2,1
	Topic: page_visits	Partition: 4	Leader: 1	Replicas: 1,0,2	Isr: 1,0,2
	Topic: page_visits	Partition: 5	Leader: 2	Replicas: 2,1,0	Isr: 2,1,0
	Topic: page_visits	Partition: 6	Leader: 0	Replicas: 0,1,2	Isr: 0,1,2
	Topic: page_visits	Partition: 7	Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: page_visits	Partition: 8	Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
	Topic: page_visits	Partition: 9	Leader: 0	Replicas: 0,2,1	Isr: 0,2,1
	Topic: page_visits	Partition: 10	Leader: 1	Replicas: 1,0,2	Isr: 1,0,2
	Topic: page_visits	Partition: 11	Leader: 2	Replicas: 2,1,0	Isr: 2,1,0
	```

1. Now we can turn our attention to the client examples in this directory.

	1. First run the example producer to publish 10 data records to Confluent Cloud.

		```shell
		# Build the client examples
		$ mvn clean package
		
		# Run the producer
		$ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.ProducerExample" \
		  -Dexec.args="$HOME/.ccloud/config page_visits 10"
		```
		You should see
		
		```
		<snipped>
		
		[2017-07-27 14:35:27,944] INFO Kafka version : 0.10.2.1-cp2 (org.apache.kafka.common.utils.AppInfoParser)
		[2017-07-27 14:35:27,944] INFO Kafka commitId : 8041e4a077aba712 (org.apache.kafka.common.utils.AppInfoParser)
		Successfully produced 10 messages to page_visits.
		....
		```
		

	1. Then, run the Kafka consumer application to read the records we just published to the Kafka cluster, and to display the records in the console.

		```shell
		# Build the client examples
		$ mvn clean package
		
		# Run the consumer
		$ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.ConsumerExample" \
		  -Dexec.args="$HOME/.ccloud/config page_visits"		
		```
		
		You should see

		```
		[INFO] Scanning for projects...
		
		<snipped>
		
		[2017-07-27 14:35:41,726] INFO Setting newly assigned partitions [page_visits-11, page_visits-10, page_visits-1, page_visits-0, page_visits-7, page_visits-6, page_visits-9, page_visits-8, page_visits-3, page_visits-2, page_visits-5, page_visits-4] for group example-1759082952 (org.apache.kafka.clients.consumer.internals.ConsumerCoordinator)
		offset = 3, key = 192.168.2.13, value = 1501191328318,www.example.com,192.168.2.13
		offset = 3, key = 192.168.2.225, value = 1501191328318,www.example.com,192.168.2.225
		....
		```
		Hit Ctrl+C to stop.
