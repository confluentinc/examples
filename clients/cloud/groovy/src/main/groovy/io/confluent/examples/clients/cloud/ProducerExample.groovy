/**
 * Copyright 2019 Confluent Inc.
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

import static io.confluent.examples.clients.cloud.util.PropertiesLoader.loadConfig
import static java.lang.System.exit
import static org.apache.kafka.clients.admin.AdminClient.*
import static org.apache.kafka.clients.producer.ProducerConfig.*

@CompileStatic
class ProducerExample {

  // Create topic in Confluent Cloud
  static void createTopic(String topic,
                          int partitions,
                          int replication,
                          Properties cloudConfig) {

    def newTopic = new NewTopic(topic, partitions, (short) replication)

    def adminClient = create cloudConfig

    adminClient.withCloseable {
      it.createTopics([newTopic]).all().get()
    }
  }

  static void main(String[] args) {
    if (args.length != 2) {
      println "Please provide command line arguments: <configPath> <topic>"
      exit 1
    }

    // Load properties from file
    def props = loadConfig(args[0])

    // Create topic if needed
    def topic = args[1]
    try {
      createTopic topic, 1, 3, props
    } catch (ExecutionException e) {
      if (!(e.cause instanceof TopicExistsException)) {
        throw new RuntimeException(e)
      }
    }

    // Add additional properties.
    props[ACKS_CONFIG] = "all"
    props[KEY_SERIALIZER_CLASS_CONFIG] = StringSerializer.name
    props[VALUE_SERIALIZER_CLASS_CONFIG] = KafkaJsonSerializer.name

    def producer = new KafkaProducer<String, DataRecord>(props)

    // Produce sample data
    final Long numMessages = 10L

    producer.withCloseable {
      for (Long i = 0L; i < numMessages; i++) {

        def key = 'alice'
        def record = new DataRecord(i)

        println "Producing record: $key\t$record\n"
        def record1 = new ProducerRecord<String, DataRecord>(topic, key, record)
        producer.send(record1, { RecordMetadata m, Exception e ->
          if (!e) {
            println "Produced record to topic ${m.topic()} partition [${m.partition()}] @ offset ${m.offset()}\n"
          } else {
            e.printStackTrace()
          }
        })
      }

      producer.flush()
      println "10 messages were produced to topic ${topic}"
    }
  }
}
