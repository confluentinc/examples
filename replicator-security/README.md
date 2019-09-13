# Replicator security configuration demos

## Overview

Confluent Replicator replicates topics from one Apache Kafka® cluster to another. In addition to copying the messages, this connector will create topics as needed preserving the topic configuration in the source cluster. This includes preserving the number of partitions, the replication factor, and any configuration overrides specified for individual topics.

Replicator supports all security configurations available to a Kafka clients and supports scenarios where the source cluster has different security to the destination cluster. Replicator runs as a source connector in the destination cluster taking advantage of Kafka Connects configuration and resiliency features. Because of this Replicator requires that security configurations for the destination cluster are supplied to both Kafka Connect and Replicator configurations. Please see the documentation [here](https://docs.confluent.io/current/installation/docker/installation/replicator.html) for more in-depth understanding of how Replicator works in multi data center environments.  

This demo provides several docker-compose environments for Replicator configured with various security configurations.

The scripts directory provides example JSON Replicator configurations for each security mechanism discussed. You can diff these to determine the correct properties to add for your chosen security mechanism. e.g:
 
```
diff scripts/submit_replicator_unsecure.sh scripts/submit_replicator_source_ssl_encryption.sh
```

## Components

In addition to Confluent Replicator, all environments contain:

* A 3 node source cluster containing srcKafka1, srcKafka2 and srcKafka3
* A 3 node destination cluster containing destKafka1, destKafka2, destKafka3
* A single Connect worker that will run replicator
* A source client container (srcKafkaClient) that creates a source topic and provides test data
* A destination client container (destKafkaClient) that installs Replicator

In all containers, minimal non-replicator configuration is supplied.

## Test Data

The [test data](testData/testData.txt) is loaded into the source topic, and it can be modified to suit testing requirements.

## Creating and verifying the environments

In all environments no actions are taken on the destination brokers. Because of this we can verify the environment by consuming from the test topic on the destination cluster.

### Unsecured

Source Cluster: Unsecure

Destination Cluster: Unsecure

Run:
  ```
  docker-compose -f docker-compose_unsecure.yml up -d
  ```
  
Verify:
  ```
  docker-compose -f docker-compose_unsecure.yml exec destKafka1 kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --from-beginning
  ```

### Source Cluster with SSL encryption

Source Cluster: SSL Encryption

Destination Cluster: Unsecure

Run:
  ```
  docker-compose -f docker-compose_source_ssl_encryption.yml up -d
  ```
  
Verify:
  ```
  docker-compose -f docker-compose_source_ssl_encryption.yml exec destKafka1 kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification  
  
### Destination Cluster with SSL encryption

Source Cluster: Unsecure

Destination Cluster: SSL Encryption

Run:
  ```
  docker-compose -f docker-compose_dest_ssl_encryption.yml up -d
  ```
  
Verify:
  ```
  docker-compose -f docker-compose_dest_ssl_encryption.yml exec destKafka1 kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --consumer.config /etc/kafka/secrets/destKafkaClient_ssl.properties --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification 

### Source Cluster with SSL authentication

Source Cluster: SSL Authentication

Destination Cluster: Unsecure

Run:
  ```
  docker-compose -f docker-compose_source_ssl_auth.yml up -d
  ```
  
Verify:
  ```
  docker-compose -f docker-compose_source_ssl_auth.yml exec destKafka1 kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification 

### Destination Cluster with SSL authentication

Source Cluster: Unsecure

Destination Cluster: SSL Authentication

Run:
  ```
  docker-compose -f docker-compose_dest_ssl_auth.yml up -d
  ```
  
Verify:
  ```
  docker-compose -f docker-compose_dest_ssl_auth.yml exec destKafka1 kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --consumer.config /etc/kafka/secrets/destKafkaClient_ssl.properties --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification 

### Source Cluster with SASL Plain authentication

Source Cluster: SASL Authentication

Destination Cluster: Unsecure

Run:
  ```
  docker-compose -f docker-compose_source_sasl_plain_auth.yml up -d
  ```
  
Verify:
  ```
  docker-compose -f docker-compose_source_sasl_plain_auth.yml exec destKafka1 kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification 

### Destination Cluster with SASL Plain authentication

Source Cluster: Unsecure

Destination Cluster: SASL Authentication

Run:
  ```
  docker-compose -f docker-compose_dest_sasl_plain_auth.yml up -d
  ```
  
Verify:
  ```
  docker-compose -f docker-compose_dest_sasl_plain_auth.yml exec destKafka1 kafka-console-consumer --bootstrap-server localhost:11091 --consumer.config /etc/kafka/secrets/destKafkaClient_sasl.properties --topic testTopic --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification 
