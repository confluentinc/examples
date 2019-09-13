# Replicator security configuration demos

## Overview

This demo provides several docker-compose environments for Replicator configured with various security configurations.

## Components

All environments contain:

* A 3 node source cluster containing srcKafka1, srcKafka2 and srcKafka3
* A 3 node destination cluster containing destKafka1, destKafka2, destKafka3
* A single Connect worker that will run replicator
* A source client container (srcKafkaClient) that creates a source topic and provides test data
* A destination client container (destKafkaClient) that installs Replicator

In all containers, minimal non-replicator configuration is supplied.

## Test Data

The data from testData/testData.txt is loaded into the source topic, this can be modified to suit testing requirements.

## Creating and verifying the environments

In all environments no actions are taken on the destination brokers. Because of this we can verify the environment by consuming from the test topic on the destination cluster.

* Unsecured

  This can be started with:
  ```
  docker-compose -f docker-compose_unsecure.yml up -d
  ```
  
  And verified as follows:
  ```
  docker-compose -f docker-compose_unsecure.yml exec destKafka1 bash
  kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --from-beginning
  ```

* Source Cluster with SSL encryption

  This can be started with:
  ```
  docker-compose -f docker-compose_source_ssl_encryption.yml up -d
  ```
  
  And verified as follows:
  ```
  docker-compose -f docker-compose_source_ssl_encryption.yml exec destKafka1 bash
  kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification  
  
* Destination Cluster with SSL encryption

  This can be started with:
  ```
  docker-compose -f docker-compose_dest_ssl_encryption.yml up -d
  ```
  
  And verified as follows:
  ```
  docker-compose -f docker-compose_dest_ssl_encryption.yml exec destKafka1 bash
  kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --consumer.config /etc/kafka/secrets/destKafkaClient_ssl.properties --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification 

* Source Cluster with SSL authentication

  This can be started with:
  ```
  docker-compose -f docker-compose_source_ssl_auth.yml up -d
  ```
  
  And verified as follows:
  ```
  docker-compose -f docker-compose_source_ssl_auth.yml exec destKafka1 bash
  kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification 

* Destination Cluster with SSL authentication

  This can be started with:
  ```
  docker-compose -f docker-compose_dest_ssl_auth.yml up -d
  ```
  
  And verified as follows:
  ```
  docker-compose -f docker-compose_dest_ssl_auth.yml exec destKafka1 bash
  kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --consumer.config /etc/kafka/secrets/destKafkaClient_ssl.properties --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification 

* Source Cluster with SASL Plain authentication

  This can be started with:
  ```
  docker-compose -f docker-compose_source_sasl_plain_auth.yml up -d
  ```
  
  And verified as follows:
  ```
  docker-compose -f docker-compose_source_sasl_plain_auth.yml exec destKafka1 bash
  kafka-console-consumer --bootstrap-server localhost:11091 --topic testTopic --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification 

* Destination Cluster with SASL Plain authentication

  This can be started with:
  ```
  docker-compose -f docker-compose_dest_sasl_plain_auth.yml up -d
  ```
  
  And verified as follows:
  ```
  docker-compose -f docker-compose_dest_sasl_plain_auth.yml exec destKafka1 bash
  kafka-console-consumer --bootstrap-server localhost:11091 --consumer.config /etc/kafka/secrets/destKafkaClient_sasl.properties --topic testTopic --from-beginning
  ```
  
  Note: both the srcKafkaClient and destKafkaClient containers must complete and exit 0 before verification 
