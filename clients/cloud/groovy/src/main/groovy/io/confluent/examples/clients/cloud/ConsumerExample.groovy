/*
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
import static io.confluent.kafka.serializers.KafkaJsonDeserializerConfig.JSON_VALUE_TYPE
import static java.lang.System.exit
import static org.apache.kafka.clients.consumer.ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG
import static org.apache.kafka.clients.consumer.ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG
import static org.apache.kafka.clients.consumer.ConsumerConfig.GROUP_ID_CONFIG
import static org.apache.kafka.clients.consumer.ConsumerConfig.AUTO_OFFSET_RESET_CONFIG

import groovy.transform.CompileStatic
import io.confluent.examples.clients.cloud.model.DataRecord
import io.confluent.kafka.serializers.KafkaJsonDeserializer
import org.apache.kafka.clients.consumer.KafkaConsumer
import org.apache.kafka.common.serialization.StringDeserializer

import java.time.Duration

@CompileStatic
class ConsumerExample {

  static void main(String[] args) throws Exception {
    if (args.length != 2) {
      println 'Please provide command line arguments: <configPath> <topic>'
      exit 1
    }

    def topic = args[1]

    // Load properties from disk.
    def config = loadConfig(args[0])

    // Add additional properties.
    config[KEY_DESERIALIZER_CLASS_CONFIG] = StringDeserializer.name
    config[VALUE_DESERIALIZER_CLASS_CONFIG] = KafkaJsonDeserializer.name
    config[JSON_VALUE_TYPE] = DataRecord
    config[GROUP_ID_CONFIG] = 'groovy_example_group_1'
    config[AUTO_OFFSET_RESET_CONFIG] = 'earliest'

    def consumer = new KafkaConsumer<String, DataRecord>(config)
    consumer.subscribe([topic] as List<String>)

    def totalCount = 0L

    consumer.withCloseable {
      while (true) {
        def records = consumer.poll Duration.ofMillis(100)
        for (record in records) {
          def value = record.value()
          totalCount += value.count

          println "Consumed record with key ${record.key()} and value $value, and updated total count to $totalCount\n"
        }
      }
    }
  }
}
