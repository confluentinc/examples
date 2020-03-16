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
@file:JvmName("ConsumerExample")

package io.confluent.examples.clients.cloud

import io.confluent.examples.clients.cloud.model.DataRecord
import io.confluent.examples.clients.cloud.util.loadConfig
import io.confluent.kafka.serializers.KafkaJsonDeserializer
import io.confluent.kafka.serializers.KafkaJsonDeserializerConfig.JSON_VALUE_TYPE
import org.apache.kafka.clients.consumer.ConsumerConfig.*
import org.apache.kafka.clients.consumer.KafkaConsumer
import org.apache.kafka.common.serialization.StringDeserializer
import java.time.Duration.ofMillis
import kotlin.system.exitProcess

fun main(args: Array<String>) {

  if (args.size != 2) {
    println("Please provide command line arguments: configPath topic")
    exitProcess(1)
  }

  val topic = args[1]

  // Load properties from disk.
  val props = loadConfig(args[0])

  // Add additional properties.
  props[KEY_DESERIALIZER_CLASS_CONFIG] = StringDeserializer::class.java.name
  props[VALUE_DESERIALIZER_CLASS_CONFIG] = KafkaJsonDeserializer::class.java.name
  props[JSON_VALUE_TYPE] = DataRecord::class.java
  props[GROUP_ID_CONFIG] = "kotlin_example_group_1"
  props[AUTO_OFFSET_RESET_CONFIG] = "earliest"

  val consumer = KafkaConsumer<String, DataRecord>(props).apply {
    subscribe(listOf(topic))
  }

  var totalCount = 0L

  consumer.use {
    while (true) {
      totalCount = consumer
          .poll(ofMillis(100))
          .fold(totalCount, { accumulator, record ->
            val newCount = accumulator + 1
            println("Consumed record with key ${record.key()} and value ${record.value()}, and updated total count to $newCount")
            newCount
          })
    }
  }
}

