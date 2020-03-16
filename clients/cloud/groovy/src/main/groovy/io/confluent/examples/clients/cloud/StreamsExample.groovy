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
import static java.lang.System.exit
import static org.apache.kafka.clients.consumer.ConsumerConfig.AUTO_OFFSET_RESET_CONFIG
import static org.apache.kafka.streams.StreamsConfig.APPLICATION_ID_CONFIG
import static org.apache.kafka.streams.StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG
import static org.apache.kafka.streams.StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG
import static org.apache.kafka.streams.StreamsConfig.CACHE_MAX_BYTES_BUFFERING_CONFIG
import static org.apache.kafka.streams.StreamsConfig.REPLICATION_FACTOR_CONFIG

import groovy.transform.CompileStatic
import io.confluent.examples.clients.cloud.model.DataRecord
import io.confluent.kafka.serializers.KafkaJsonDeserializer
import io.confluent.kafka.serializers.KafkaJsonSerializer
import org.apache.kafka.common.serialization.Serde
import org.apache.kafka.common.serialization.Serdes
import org.apache.kafka.streams.KafkaStreams
import org.apache.kafka.streams.KeyValue
import org.apache.kafka.streams.StreamsBuilder
import org.apache.kafka.streams.kstream.Consumed
import org.apache.kafka.streams.kstream.KStream
import org.apache.kafka.streams.kstream.KeyValueMapper
import org.apache.kafka.streams.kstream.Printed
import org.apache.kafka.streams.kstream.Reducer

@CompileStatic
class StreamsExample {

  static void main(String[] args) throws Exception {

    if (args.length != 2) {
      println 'Please provide command line arguments: configPath topic'
      exit 1
    }

    String topic = args[1]

    // Load properties from disk.
    Properties config = loadConfig args[0]

    config[APPLICATION_ID_CONFIG] = 'groovy_streams_example_group_1'
    config[DEFAULT_KEY_SERDE_CLASS_CONFIG] = Serdes.String().class.name
    config[DEFAULT_VALUE_SERDE_CLASS_CONFIG] = Serdes.Long().class.name

    // Disable caching to print the aggregation value after each record
    config[CACHE_MAX_BYTES_BUFFERING_CONFIG] = 0
    config[REPLICATION_FACTOR_CONFIG] = 3
    config[AUTO_OFFSET_RESET_CONFIG] = 'earliest'

    def builder = new StreamsBuilder()
    def records = builder.stream topic, Consumed.with(Serdes.String(), jsonSerde())

    def counts = records.map new KeyValueMapper<String, DataRecord, KeyValue<String, Long>>() {

      @Override
      KeyValue<String, Long> apply(String key, DataRecord value) {
        new KeyValue<String, Long>(key, value.count)
      }
    }

    counts.print(Printed.<String, Long> toSysOut().withLabel('Consumed record'))

    // Aggregate values by key
    KStream<String, Long> countAgg = counts
        .groupByKey()
        .reduce(new Reducer<Long>() {

      @Override
      Long apply(Long aggValue, Long newValue) {
        aggValue + newValue
      }
    }).toStream()

    countAgg.print(Printed.<String, Long> toSysOut().withLabel('Running count'))

    def streams = new KafkaStreams(builder.build(), config)
    streams.start()

    // Add shutdown hook to respond to SIGTERM and gracefully close Kafka Streams
    Runtime.runtime.addShutdownHook(new Thread(new Runnable() {

      @Override
      void run() {
        streams.close()
      }
    }))

  }

  private static Serde<DataRecord> jsonSerde() {

    def serdeProps = [:]
    serdeProps['json.value.type'] = DataRecord

    def mySerializer = new KafkaJsonSerializer<>()
    mySerializer.configure serdeProps, false

    def myDeserializer = new KafkaJsonDeserializer<>()
    myDeserializer.configure serdeProps, false

    Serdes.serdeFrom mySerializer, myDeserializer
  }

}
