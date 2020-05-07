# Overview

## Programming Languages

This directory includes examples of Kafka client applications, showcasing producers and consumers, written in various programming languages.
The README for each language walks through the necessary steps to run each example.
Each client example takes as an argument a properties file with the configuration parameters that specify connection information for any of the following:

* Kafka cluster running on your local host (Download [Confluent Platform](https://www.confluent.io/download/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud))
* [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud)
* Any other remote Kafka cluster

Click on any language in the table below:

|                                   |                                                 |                                   |
|:---------------------------------:|:-----------------------------------------------:|:---------------------------------:|
| [![](images/java.png)](java/)     | [![](images/python.png)](python/)               | [![](images/go.png)](go/)         |
| [![](images/scala.png)](scala/)   | [![](images/confluent-cli.png)](confluent-cli/) | [![](images/ruby.png)](ruby/)     |
| [![](images/groovy.png)](groovy/) | [![](images/kotlin.png)](kotlin/)               | [![](images/nodejs.png)](nodejs/) |
| [![](images/kafkacat.jpg)](kafkacat/) | [![](images/dotnet.png)](csharp/)           | [![](images/c.png)](c/) |
| [![](images/kafka-connect-datagen.png)](kafka-connect-datagen/) | [![](images/ksql-datagen.png)](ksql-datagen/) | [![](images/rust.png)](rust/) |
| [![](images/kafka.png)](kafka-commands/) | [![](images/clojure.png)](clojure/) | [![](images/springboot.png)](java-springboot/) |

## With Schema Registry

The following subset includes examples with Schema Registry and Avro data:

|                                   |                                                 |                                   |
|:---------------------------------:|:-----------------------------------------------:|:---------------------------------:|
| [![](images/java.png)](java/)     | [![](images/python.png)](python/)               | [![](images/confluent-cli.png)](confluent-cli/) |
| [![](images/kafka-connect-datagen.png)](kafka-connect-datagen/) | [![](images/ksql-datagen.png)](ksql-datagen/) | [![](images/kafka.png)](kafka-commands/) |

# Additional Resources


* For clusters in Confluent Cloud: refer to [Best Practices for Developing Kafka Applications on Confluent Cloud](https://assets.confluent.io/m/14397e757459a58d/original/20200205-WP-Best_Practices_for_Developing_Apache_Kafka_Applications_on_Confluent_Cloud.pdf?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients) whitepaper for a practical guide to configuring, monitoring, and optimizing your Kafka client applications.
* For on-prem clusters: refer to [Optimizing Your Apache Kafka Deployment](https://www.confluent.io/white-paper/optimizing-your-apache-kafka-deployment?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients) whitepaper for a practical guide to optimizing your Apache Kafka deployment for various services goals including throughput, latency, durability and availability, and useful metrics to monitor for performance and cluster health.
