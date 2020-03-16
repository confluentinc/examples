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
@file:JvmName("ProducerExample")

package io.confluent.examples.clients.cloud

import io.confluent.examples.clients.cloud.model.DataRecord
import io.confluent.examples.clients.cloud.util.loadConfig
import io.confluent.kafka.serializers.KafkaJsonSerializer
import org.apache.kafka.clients.admin.AdminClient
import org.apache.kafka.clients.admin.NewTopic
import org.apache.kafka.clients.producer.KafkaProducer
import org.apache.kafka.clients.producer.ProducerConfig.*
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.clients.producer.RecordMetadata
import org.apache.kafka.common.errors.TopicExistsException
import org.apache.kafka.common.serialization.StringSerializer
import java.util.*
import java.util.concurrent.ExecutionException
import kotlin.system.exitProcess

// Create topic in Confluent Cloud
fun createTopic(topic: String,
                partitions: Int,
                replication: Short,
                cloudConfig: Properties) {
  val newTopic = NewTopic(topic, partitions, replication)


  try {
    with(AdminClient.create(cloudConfig)) {
      createTopics(listOf(newTopic)).all().get()
    }
  } catch (e: ExecutionException) {
    if (e.cause !is TopicExistsException) throw e
  }
}

fun main(args: Array<String>) {
  if (args.size != 2) {
    println("Please provide command line arguments: configPath topic")
    exitProcess(1)
  }

  // Load properties from file
  val props = loadConfig(args[0])

  // Create topic if needed
  val topic = args[1]
  createTopic(topic, 1, 3, props)

  // Add additional properties.
  props[ACKS_CONFIG] = "all"
  props[KEY_SERIALIZER_CLASS_CONFIG] = StringSerializer::class.qualifiedName
  props[VALUE_SERIALIZER_CLASS_CONFIG] = KafkaJsonSerializer::class.qualifiedName

  // Produce sample data
  val numMessages = 10
  // `use` will execute block and close producer automatically  
  KafkaProducer<String, DataRecord>(props).use { producer ->
    repeat(numMessages) { i ->
      val key = "alice"
      val record = DataRecord(i.toLong())
      println("Producing record: $key\t$record")

      producer.send(ProducerRecord(topic, key, record)) { m: RecordMetadata, e: Exception? ->
        when (e) {
          // no exception, good to go!
          null -> println("Produced record to topic ${m.topic()} partition [${m.partition()}] @ offset ${m.offset()}")
          // print stacktrace in case of exception
          else -> e.printStackTrace()
        }
      }
    }

    producer.flush()
    println("10 messages were produced to topic $topic")
  }

}


