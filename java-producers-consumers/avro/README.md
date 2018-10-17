# Java Producer and Consumer with Avro

This directory includes projects demonstrating how to use the Java producer and consumer with Avro and Confluent Schema Registry

For more information, please see the [application development documentation](https://docs.confluent.io/current/api-javadoc.html)


# Quickstart

1. Before you start, you must start a local Kafka cluster with Confluent CLI.

```
$ confluent start
```

Then you may proceed:

2. Run the example producer to publish 10 data records with Avro and Confluent Schema Registry

		```
		# Build the client examples
		$ mvn clean package
		
		# Run the producer
                $ mvn exec:java -f pom.xml -Dexec.mainClass=io.confluent.examples.clients.basicavro.ProducerExample
		```

		You should see
		
		```
                ....
                Successfully produced 10 messages to a topic called payments
		....
		```
		

3. Run the example consumer to read the records we just published to the Kafka cluster, and to display the records in the console.

		```
		# Build the client examples
		$ mvn clean package
		
		# Run the consumer
		$ mvn exec:java -f pom.xml -Dexec.mainClass=io.confluent.examples.clients.basicavro.ConsumerExample
		```
		
		You should see

		```
                ....
                offset = 0, key = id0, value = {"id": "id0", "amount": 1000.0}
                offset = 1, key = id1, value = {"id": "id1", "amount": 1000.0}
                offset = 2, key = id2, value = {"id": "id2", "amount": 1000.0}
                offset = 3, key = id3, value = {"id": "id3", "amount": 1000.0}
                offset = 4, key = id4, value = {"id": "id4", "amount": 1000.0}
                offset = 5, key = id5, value = {"id": "id5", "amount": 1000.0}
                offset = 6, key = id6, value = {"id": "id6", "amount": 1000.0}
                offset = 7, key = id7, value = {"id": "id7", "amount": 1000.0}
                offset = 8, key = id8, value = {"id": "id8", "amount": 1000.0}
                offset = 9, key = id9, value = {"id": "id9", "amount": 1000.0}
		....
		```

		Hit Ctrl+C to stop.


        3. Use the command line to view the same messages in the topic `payments`

		```
                $ confluent consume payments --from-beginning --value-format avro --from-beginning
                This CLI is intended for development only, not for production
                https://docs.confluent.io/current/cli/index.html
                
                {"id":"id0","amount":1000.0}
                {"id":"id1","amount":1000.0}
                {"id":"id2","amount":1000.0}
                {"id":"id3","amount":1000.0}
                {"id":"id4","amount":1000.0}
                {"id":"id5","amount":1000.0}
                {"id":"id6","amount":1000.0}
                {"id":"id7","amount":1000.0}
                {"id":"id8","amount":1000.0}
                {"id":"id9","amount":1000.0}
                ```

         4. View the schema associated to the topic `payments` value.

                ```
                $ curl -X GET http://localhost:8081/subjects/payments-value/versions/latest | jq .
                {
                  "subject": "payments-value",
                  "version": 1,
                  "id": 1,
                  "schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}]}"
                }
                ```

