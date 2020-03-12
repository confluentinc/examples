/**
 * Copyright 2020 Confluent Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package io.confluent.examples.clients.cloud

import static io.confluent.examples.clients.cloud.util.PropertiesLoader.loadConfig
import static java.lang.System.exit
import static org.apache.kafka.clients.producer.ProducerConfig.ACKS_CONFIG
import static org.apache.kafka.clients.producer.ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG
import static org.apache.kafka.clients.producer.ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG

import groovy.transform.CompileStatic
import io.confluent.examples.clients.cloud.model.DataRecord
import io.confluent.kafka.serializers.KafkaJsonSerializer
import org.apache.kafka.clients.admin.AdminClient
import org.apache.kafka.clients.admin.NewTopic
import org.apache.kafka.clients.producer.KafkaProducer
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.clients.producer.RecordMetadata
import org.apache.kafka.common.errors.TopicExistsException
import org.apache.kafka.common.serialization.StringSerializer

import java.util.concurrent.ExecutionException

@CompileStatic
class ProducerExample {

  // Create topic in Confluent Cloud
  static void newTopic(String topic,
                       int partitions,
                       int replication,
                       Properties cloudConfig) {

    def newTopic = new NewTopic(topic, partitions, (short) replication)

    def adminClient = AdminClient.create cloudConfig

    adminClient.withCloseable { client ->
      client.createTopics([newTopic]).all().get()
    }
  }

  static void main(String[] args) {
    if (args.length != 2) {
      println 'Please provide command line arguments: <configPath> <topic>'
      exit 1
    }

    // Load properties from file
    def config = loadConfig args[0]

    // Create topic if needed
    def topic = args[1]
    try {
      newTopic topic, 1, 3, config
    } catch (ExecutionException e) {
      if (!(e.cause.class == TopicExistsException)) {
        throw e
      }
    }

    // Add additional properties.
    config[ACKS_CONFIG] = 'all'
    config[KEY_SERIALIZER_CLASS_CONFIG] = StringSerializer.name
    config[VALUE_SERIALIZER_CLASS_CONFIG] = KafkaJsonSerializer.name

    def producer = new KafkaProducer<String, DataRecord>(config)

    // Produce sample data
    final numMessages = 10L

    producer.withCloseable {
      for (def i = 0L; i < numMessages; i++) {

        def key = 'alice'
        def record = new DataRecord(i)

        println "Producing record: $key\t$record\n"
        def record1 = new ProducerRecord<String, DataRecord>(topic, key, record)
        producer.send record1, { RecordMetadata metadata, Exception e ->
          if (e) {
            e.printStackTrace()
          } else {
            println "Produced record to topic ${metadata.topic()} partition [${metadata.partition()}] @ offset ${metadata.offset()}\n"
          }
        }
      }

      producer.flush()
      println "10 messages were produced to topic ${topic}"
    }
  }
}
