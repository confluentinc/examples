/**
  * Copyright 2015 Confluent Inc.
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
import java.util.{Collections, Properties}

import io.confluent.examples.clients.scala.model.RecordJSON
import org.apache.kafka.common.serialization.{Deserializer, Serde}
import org.apache.kafka.common.serialization.Serde
import org.apache.kafka.common.serialization.Serdes
import org.apache.kafka.common.serialization.Serializer
import io.confluent.kafka.serializers.KafkaJsonDeserializer
import io.confluent.kafka.serializers.KafkaJsonSerializer
import org.apache.kafka.streams.{KafkaStreams, KeyValue, StreamsBuilder}
import org.apache.kafka.streams.kstream.{Consumed, KStream, Printed, Serialized}

object Streams extends App {
  val configFileName = args(0)
  val topicName = args(1)
  val props = buildProperties(configFileName)

  val RecordJSON: Serde[RecordJSON] = getJsonSerde()

  val builder = new StreamsBuilder

  val records :KStream[String, RecordJSON] = builder.stream(topicName, Consumed.`with`(Serdes.String, RecordJSON))
  val counts :KStream[String,Long] = records.map((k: String, v: RecordJSON) => new KeyValue[String, Long](k, v.getCount))
  counts.print(Printed.toSysOut[String,Long].withLabel("Consumed record"))

  // Aggregate values by key
  val countAgg :KStream[String,Long] = counts.groupByKey()
    .reduce((aggValue, newValue) => aggValue + newValue)
    .toStream()
  countAgg.print(Printed.toSysOut[String,Long].withLabel("Running count"))

  val streams = new KafkaStreams(builder.build, props)
  streams.start()

  // Add shutdown hook to respond to SIGTERM and gracefully close Kafka Streams
  Runtime.getRuntime.addShutdownHook(new Thread(new Runnable(){override def run{streams.close}}))


  /*?************/

  def buildProperties(configFileName: String): Properties = {
    import org.apache.kafka.clients.consumer.ConsumerConfig
    import org.apache.kafka.streams.StreamsConfig
    val properties = new Properties()
    properties.put(StreamsConfig.APPLICATION_ID_CONFIG, "java_streams_example_group")
    // Disable caching to print the aggregation value after each record
    properties.put(StreamsConfig.CACHE_MAX_BYTES_BUFFERING_CONFIG, "0")
    properties.put(StreamsConfig.REPLICATION_FACTOR_CONFIG, "3")
    properties.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest")
    properties.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass)
    properties.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.Long().getClass)
    properties.load(new FileReader(configFileName))
    properties
  }


  private def getJsonSerde():Serde[RecordJSON]  = {
    val serdeProps: java.util.Map[String, Object] = Collections.singletonMap("json.value.type", classOf[RecordJSON])
    val mySerializer:Serializer[RecordJSON] =  new KafkaJsonSerializer[RecordJSON]()
    mySerializer.configure(serdeProps, false)
    val myDeserializer:Deserializer[RecordJSON] = new KafkaJsonDeserializer[RecordJSON]()
    myDeserializer.configure(serdeProps, false)
    Serdes.serdeFrom(mySerializer, myDeserializer)
  }

}
