/*
 * Copyright 2017 Confluent Inc.
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

package io.confluent.examples.connectandstreams.consoleproducer;

import java.util.Properties;

import org.apache.kafka.common.serialization.Serdes;

import org.apache.kafka.clients.consumer.ConsumerConfig;

import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.Printed;
import org.apache.kafka.streams.kstream.Serialized;
import org.apache.kafka.streams.kstream.Materialized;
import org.apache.kafka.common.utils.Bytes;
import org.apache.kafka.streams.state.KeyValueStore;

import io.confluent.examples.connectandstreams.avro.Location;

public class StreamsIngest {

  static final String INPUT_TOPIC = "consoleproducer-locations";
  static final String DEFAULT_BOOTSTRAP_SERVERS = "localhost:9092";
  static final String KEYS_STORE = "consoleproducer-count-keys";
  static final String SALES_STORE = "consoleproducer-aggregate-sales";

  public static void main(String[] args) throws Exception {

    if (args.length > 1) {
      throw new IllegalArgumentException("usage: ... "
          + "[<bootstrap.servers> (optional, default: " + DEFAULT_BOOTSTRAP_SERVERS + ")] ");
    }

    final String bootstrapServers = args.length > 0 ? args[0] : DEFAULT_BOOTSTRAP_SERVERS;

    System.out.println("Connecting to Kafka cluster via bootstrap servers " + bootstrapServers);

    final StreamsBuilder builder = new StreamsBuilder();

    Properties streamsConfiguration = new Properties();
    streamsConfiguration.put(StreamsConfig.APPLICATION_ID_CONFIG, "consoleproducer");
    streamsConfiguration.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    streamsConfiguration.put(StreamsConfig.COMMIT_INTERVAL_MS_CONFIG, 1000);
    streamsConfiguration.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
  
    final KStream<String, String> inputData = builder.stream(INPUT_TOPIC,
        Consumed.with(Serdes.String(), Serdes.String()));
    inputData.print(Printed.toSysOut());
  
    // The value is a String with another '|' separator so we need to split it again
    // This is obviously messy but is shown just to demonstrate how messy it can be
    // without well-structured data
    KStream<Long, Location> locations = inputData.map((k, v) ->
        new KeyValue<Long, Location>(Long.parseLong(k), new Location(Long.parseLong(k),
        v.split("\\|")[0], Long.parseLong(v.split("\\|")[1]))));
    locations.print(Printed.toSysOut());

    KStream<Long,Long> sales = locations.map((k, v) -> new KeyValue<Long, Long>(k, v.getSale()));

    // Count occurrences of each key
    KStream<Long, Long> countKeys = sales.groupByKey(Serialized.with(Serdes.Long(), Serdes.Long()))
        .count(Materialized.<Long, Long, KeyValueStore<Bytes, byte[]>>as(KEYS_STORE)
            .withValueSerde(Serdes.Long()))
        .toStream();
    countKeys.print(Printed.toSysOut());

    // Aggregate values by key
    KStream<Long,Long> salesAgg = sales.groupByKey(Serialized.with(Serdes.Long(), Serdes.Long()))
        .reduce(
            (aggValue, newValue) -> aggValue + newValue)
        .toStream();
    salesAgg.print(Printed.toSysOut());

    KafkaStreams streams = new KafkaStreams(builder.build(), streamsConfiguration);
    streams.start();

    // Add shutdown hook to respond to SIGTERM and gracefully close Kafka Streams
    Runtime.getRuntime().addShutdownHook(new Thread(streams::close));

  }

}
