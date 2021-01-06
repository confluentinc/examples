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
package io.confluent.examples.clients.scala

import java.io.FileReader
import java.time.Duration
import java.util.{Collections, Properties}

import com.fasterxml.jackson.databind.{JsonNode, ObjectMapper}
import org.apache.kafka.clients.consumer.{ConsumerConfig, KafkaConsumer}
import io.confluent.examples.clients.scala.model.RecordJSON

import scala.collection.JavaConversions._

  object Consumer extends App {
    val configFileName = args(0)
    val topicName = args(1)
    val props = buildProperties(configFileName)
    val consumer = new KafkaConsumer[String, JsonNode](props)
    val MAPPER = new ObjectMapper
    consumer.subscribe(Collections.singletonList(topicName))
    var total_count = 0L
    while(true) {
      println("Polling")
      val records = consumer.poll(Duration.ofSeconds(1))
      for (record <- records) {
        val key = record.key()
        val value = record.value()
        val countRecord = MAPPER.treeToValue(value, classOf[RecordJSON])
        total_count += countRecord.getCount
        println(s"Consumed record with key $key and value $value, and updated total count to $total_count")
      }
    }
    consumer.close()
    
    def buildProperties(configFileName: String): Properties = {
      val properties = new Properties()
      properties.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer")
      properties.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.connect.json.JsonDeserializer")
      properties.put(ConsumerConfig.GROUP_ID_CONFIG, "scala_example_group")
      properties.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest")
      properties.load(new FileReader(configFileName))
      properties
    }

}
