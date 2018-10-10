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

package io.confluent.examples.connectandstreams.javaproducer;

import java.util.Properties;

import org.apache.kafka.clients.consumer.ConsumerConfig;

import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.kstream.KGroupedStream;
import org.apache.kafka.streams.kstream.Printed;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.Serialized;
import org.apache.kafka.streams.kstream.Materialized;
import org.apache.kafka.common.utils.Bytes;
import org.apache.kafka.streams.state.KeyValueStore;

import io.confluent.kafka.serializers.AbstractKafkaAvroSerDeConfig;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerializer;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerde;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import io.confluent.examples.connectandstreams.avro.Location;

import java.util.Collections;

public class StreamsIngest {

    static final String INPUT_TOPIC = "javaproducer-locations";
    static final String DEFAULT_BOOTSTRAP_SERVERS = "localhost:9092";
    static final String DEFAULT_SCHEMA_REGISTRY_URL = "http://localhost:8081";
    static final String KEYS_STORE = "javaproducer-count-keys";
    static final String SALES_STORE = "javaproducer-aggregate-sales";

    public static void main(String[] args) throws Exception {

        if (args.length > 2) {
            throw new IllegalArgumentException("usage: ... " +
                "[<bootstrap.servers> (optional, default: " + DEFAULT_BOOTSTRAP_SERVERS + ")] " +
                "[<schema.registry.url> (optional, default: " + DEFAULT_SCHEMA_REGISTRY_URL + ")] ");
            }

        final String bootstrapServers = args.length > 0 ? args[0] : DEFAULT_BOOTSTRAP_SERVERS;
        final String SCHEMA_REGISTRY_URL = args.length > 1 ? args[1] : DEFAULT_SCHEMA_REGISTRY_URL;

        System.out.println("Connecting to Kafka cluster via bootstrap servers " + bootstrapServers);
        System.out.println("Connecting to Confluent schema registry at " + SCHEMA_REGISTRY_URL);

        final StreamsBuilder builder = new StreamsBuilder();

        Properties streamsConfiguration = new Properties();
        streamsConfiguration.put(StreamsConfig.APPLICATION_ID_CONFIG, "javaproducer");
        streamsConfiguration.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        streamsConfiguration.put(StreamsConfig.COMMIT_INTERVAL_MS_CONFIG, 1000);
        streamsConfiguration.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        final Serde<Location> locationSerde = new SpecificAvroSerde<>();
        final boolean isKeySerde = false;
        locationSerde.configure(
            Collections.singletonMap(AbstractKafkaAvroSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG, SCHEMA_REGISTRY_URL),
            isKeySerde);

        KStream<Long, Location> locations = builder.stream(INPUT_TOPIC, Consumed.with(Serdes.Long(), locationSerde));
        locations.print(Printed.toSysOut());

        KStream<Long,Long> sales = locations.map((k, v) -> new KeyValue<Long, Long>(k, v.getSale()));

        // Count occurrences of each key
        KStream<Long, Long> countKeys = sales.groupByKey(Serialized.with(Serdes.Long(), Serdes.Long()))
            .count(Materialized.<Long, Long, KeyValueStore<Bytes, byte[]>>as(KEYS_STORE).withValueSerde(Serdes.Long()))
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
