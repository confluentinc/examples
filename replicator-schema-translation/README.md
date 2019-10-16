# Replicator Schema Translation Demo

## Overview

Confluent Replicator features the ability to translate entries from a source Schema Registry to a destination Schema Registry.

This demo provides a docker-compose environment with source and destination Schema Registries in which Schemas will be translated. In this demo we will create an entry in the source Schema Registry and translate it to the destination.

The `scripts` directory provides examples of the operations that you must perform to prepare for the translation, as well as JSON Replicator configurations required.

## Prerequisites

These demos require the following tools:

* docker-compose

These demos are memory intensive and Docker must be tuned accordingly. In Docker's advanced settings, increase the memory dedicated to Docker to at least 8GB (the default is 2GB).

## Components

In addition to Confluent Replicator, the environment contains:

* A single node source cluster containing `srcKafka1`. In production, at least 3 nodes are recommended.
* A single node destination cluster containing `destKafka1`. In production, at least 3 nodes are recommended.
* A single node Schema Registry cluster containing `srcSchemaregistry`. In production, a master/standby configuration is recommended.
* A single node Schema Registry cluster containing `destSchemaregistry`. In production, a master/standby configuration is recommended.
* A single Connect worker that runs Replicator.
* A source client container (kafkaClient) that creates a source topic and provides test data

In all containers, minimal non-replicator configuration is supplied.

## Setup and verifying the environments

The demo performs the following steps:

1. Creation of a subject in the source Schema Registry
2. Preparation for Schema translation
3. Execution of Replicator to perform migration
4. Post translation Schema registry configuration. 

### Step 1: 

This step is completed automatically when the environment is started. 

Run:
  ```
  docker-compose up -d
  ```

Verify the source Schema Registry:
  ```
  curl http://localhost:8085/subjects
  ```
You should see the following:
  ```
  ["testTopic-value"]
  ```

Verify the destination Schema Registry:
  ```
  curl http://localhost:8086/subjects
  ```
You should see the following:
  ```
  []
  ```

Note: the kafkaClient container must complete and exit 0 before verification  

### Step 2: 

To prepare for Schema translation the source cluster must be put in "READONLY" mode and the destination in "IMPORT" mode.

Run:
  ```
  docker-compose exec connect /etc/kafka/scripts/set_sr_modes_pre_translation.sh
  ```

Verify: 

This should produce:
  ```
  {"mode":"READONLY"}{"mode":"IMPORT"}
  ```
### Step 3: 

Now we submit Replicator to perform the translation.

Run:
  ```
  docker-compose exec connect /etc/kafka/scripts/submit_replicator.sh
  ```

Verify: 

This should produce:
  ```
  {"name":"testReplicator","config":{"connector.class":"io.confluent.connect.replicator.ReplicatorSourceConnector","topic.whitelist":"_schemas","topic.rename.format":"${topic}.replica","key.converter":"io.confluent.connect.replicator.util.ByteArrayConverter","value.converter":"io.confluent.connect.replicator.util.ByteArrayConverter","src.kafka.bootstrap.servers":"srcKafka1:10091","dest.kafka.bootstrap.servers":"destKafka1:11091","tasks.max":"1","confluent.topic.replication.factor":"1","schema.subject.translator.class":"io.confluent.connect.replicator.schemas.DefaultSubjectTranslator","schema.registry.topic":"_schemas","schema.registry.url":"http://destSchemaregistry:8086","name":"testReplicator"},"tasks":[],"type":"source"}
  ```

Note: If replicator is submitted before the Connect worker is ready then the message below will be printed. The script will automatically retry until successful

  ```
  curl: (22) The requested URL returned error: 404 Not Found
  Failed to submit replicator to Connect. This could be because the Connect worker is not yet started. Will retry in 10 seconds
  ```

### Step 4: 

First verify the translation. 
  ```
  curl http://localhost:8086/subjects
  ```
You should see the following:
  ```
  ["testTopic.replica-value"]
  ```

Note: Replicator may not immediately translate the Schema so this verification should be retired for up to 60 seconds.

Then run:
  ```
  docker-compose exec connect /etc/kafka/scripts/set_sr_modes_post_translation.sh
  ```
Verify: 

This should produce:
  ```
  {"mode":"READWRITE"}{"mode":"READWRITE"}
  ```


