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
@file:JvmName("StreamsExample")

package io.confluent.examples.clients.cloud

import io.confluent.examples.clients.cloud.model.DataRecord
import io.confluent.examples.clients.cloud.util.loadConfig
import io.confluent.kafka.serializers.KafkaJsonDeserializer
import io.confluent.kafka.serializers.KafkaJsonSerializer
import org.apache.kafka.clients.consumer.ConsumerConfig.AUTO_OFFSET_RESET_CONFIG
import org.apache.kafka.common.serialization.Serde
import org.apache.kafka.common.serialization.Serdes
import org.apache.kafka.common.serialization.Serdes.Long
import org.apache.kafka.common.serialization.Serdes.serdeFrom
import org.apache.kafka.streams.KafkaStreams
import org.apache.kafka.streams.KeyValue
import org.apache.kafka.streams.StreamsBuilder
import org.apache.kafka.streams.StreamsConfig.*
import org.apache.kafka.streams.kstream.Consumed
import org.apache.kafka.streams.kstream.Grouped
import org.apache.kafka.streams.kstream.Printed


//DataRecord Serde
private fun dRSerde(): Serde<DataRecord> {

  val properties = hashMapOf("json.value.type" to DataRecord::class.java)

  val dRSerializer = KafkaJsonSerializer<DataRecord>()
  dRSerializer.configure(properties, false)

  val dRDeserializer = KafkaJsonDeserializer<DataRecord>()
  dRDeserializer.configure(properties, false)

  return serdeFrom(dRSerializer, dRDeserializer)
}

fun main(args: Array<String>) {

  if (args.size != 2) {
    println("Please provide command line arguments: <configPath> <topic>")
    System.exit(1)
  }

  val topic = args[1]

  // Load properties from disk.
  val props = loadConfig(args[0])
  props[APPLICATION_ID_CONFIG] = "kotlin_streams_example_group_1"
  // Disable caching to print the aggregation value after each record
  props[CACHE_MAX_BYTES_BUFFERING_CONFIG] = 0
  props[REPLICATION_FACTOR_CONFIG] = 3
  props[AUTO_OFFSET_RESET_CONFIG] = "earliest"

  val builder = StreamsBuilder()
  val records = builder.stream(topic, Consumed.with(Serdes.String(), dRSerde()))

  val counts = records.map { k, v -> KeyValue(k, v.count) }
  counts.print(Printed.toSysOut<String, Long>().withLabel("Consumed record"))

  // Aggregate values by key
  val countAgg = counts
          .groupByKey(Grouped.with(Serdes.String(), Long()))
          .reduce { aggValue, newValue -> aggValue!! + newValue!! }
          .toStream()
  countAgg.print(Printed.toSysOut<String, Long>().withLabel("Running count"))

  val streams = KafkaStreams(builder.build(), props)
  streams.start()

  // Add shutdown hook to respond to SIGTERM and gracefully close Kafka Streams
  Runtime.getRuntime().addShutdownHook(Thread(Runnable { streams.close() }))

}
