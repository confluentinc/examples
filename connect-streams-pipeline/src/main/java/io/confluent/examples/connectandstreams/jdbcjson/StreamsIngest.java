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

package io.confluent.examples.connectandstreams.jdbcjson;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.utils.Bytes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.Grouped;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.Materialized;
import org.apache.kafka.streams.kstream.Printed;
import org.apache.kafka.streams.state.KeyValueStore;

import java.util.Properties;

import io.confluent.examples.connectandstreams.jdbcjson.model.LocationJSON;
import io.confluent.examples.connectandstreams.jdbcjson.serde.JsonDeserializer;
import io.confluent.examples.connectandstreams.jdbcjson.serde.JsonSerializer;

public class StreamsIngest {

  static final String INPUT_TOPIC = "jdbcjson-locations";
  static final String DEFAULT_BOOTSTRAP_SERVERS = "localhost:9092";
  static final String KEYS_STORE = "jdbcjson-count-keys";
  static final String SALES_STORE = "jdbcjson-aggregate-sales";

  public static void main(final String[] args) {

    if (args.length > 2) {
      throw new IllegalArgumentException("usage: ... " +
                                         "[<bootstrap.servers> (optional, default: " + DEFAULT_BOOTSTRAP_SERVERS
                                         + ")] ");
    }

    final String bootstrapServers = args.length > 0 ? args[0] : DEFAULT_BOOTSTRAP_SERVERS;

    System.out.println("Connecting to Kafka cluster via bootstrap servers " + bootstrapServers);

    final StreamsBuilder builder = new StreamsBuilder();

    final Properties streamsConfiguration = new Properties();
    streamsConfiguration.put(StreamsConfig.APPLICATION_ID_CONFIG, "jdbcjson");
    streamsConfiguration.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    streamsConfiguration.put(StreamsConfig.CACHE_MAX_BYTES_BUFFERING_CONFIG, 0);
    streamsConfiguration.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

    final Serde<LocationJSON> locationSerde = Serdes.serdeFrom(new JsonSerializer<>(),
                                                               new JsonDeserializer<>(LocationJSON.class));
    final KStream<Long, LocationJSON>
        locationsJSON =
        builder.stream(INPUT_TOPIC, Consumed.with(Serdes.Long(), locationSerde));
    locationsJSON.print(Printed.toSysOut());

    final KStream<Long, Long> sales = locationsJSON.mapValues(v -> v.getSale());

    // Count occurrences of each key
    final KStream<Long, Long> countKeys = sales.groupByKey(Grouped.with(Serdes.Long(), Serdes.Long()))
        .count()
        .toStream();
    countKeys.print(Printed.toSysOut());

    // Aggregate values by key
    final KStream<Long, Long> salesAgg = sales.groupByKey(Grouped.with(Serdes.Long(), Serdes.Long()))
        .reduce(Long::sum)
        .toStream();
    salesAgg.print(Printed.toSysOut());

    final KafkaStreams streams = new KafkaStreams(builder.build(), streamsConfiguration);
    streams.start();

    // Add shutdown hook to respond to SIGTERM and gracefully close Kafka Streams
    Runtime.getRuntime().addShutdownHook(new Thread(streams::close));

  }

}
