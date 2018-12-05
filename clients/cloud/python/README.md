# Overview

Produce messages to and consume messages from Confluent Cloud using Confluent Python Client for Apache Kafka


# Prerequisites

* Install Confluent's Python Client for Apache Kafka: https://github.com/confluentinc/confluent-kafka-python
* File with client configuration parameters to connect to your Confluent Cloud instance


# Usage

$ cat ~/.ccloud/librdkafka.config
bootstrap.servers=<>
sasl.username=<>
sasl.password=<>


$ ./producer.py ~/.ccloud/librdkafka.config test1                      
alice 	 {"count": 0}
alice 	 {"count": 1}
alice 	 {"count": 2}
alice 	 {"count": 3}
alice 	 {"count": 4}
alice 	 {"count": 5}
alice 	 {"count": 6}
alice 	 {"count": 7}
alice 	 {"count": 8}
alice 	 {"count": 9}


$ ./consumer.py ~/.ccloud/librdkafka.config test1                       
alice 	 {"count": 0}
Updated total count to 0
alice 	 {"count": 1}
Updated total count to 1
alice 	 {"count": 2}
Updated total count to 3
alice 	 {"count": 3}
Updated total count to 6
alice 	 {"count": 4}
Updated total count to 10
alice 	 {"count": 5}
Updated total count to 15
alice 	 {"count": 6}
Updated total count to 21
alice 	 {"count": 7}
Updated total count to 28
alice 	 {"count": 8}
Updated total count to 36
alice 	 {"count": 9}
Updated total count to 45
end of partition: test1 [0] @ 10

