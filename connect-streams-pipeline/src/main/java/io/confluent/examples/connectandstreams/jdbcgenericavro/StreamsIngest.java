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

package io.confluent.examples.connectandstreams.jdbcgenericavro;

import java.util.Properties;

import org.apache.kafka.common.serialization.Serdes;

import org.apache.kafka.clients.consumer.ConsumerConfig;

import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KStreamBuilder;
import org.apache.kafka.streams.KeyValue;

import org.apache.avro.generic.GenericRecord;
import io.confluent.kafka.serializers.AbstractKafkaAvroSerDeConfig;
import io.confluent.kafka.streams.serdes.avro.GenericAvroSerde;
import io.confluent.examples.connectandstreams.avro.Location;

public class StreamsIngest {

    static final String INPUT_TOPIC = "jdbcgenericavro-locations";
    static final String DEFAULT_BOOTSTRAP_SERVERS = "localhost:9092";
    static final String DEFAULT_SCHEMA_REGISTRY_URL = "http://localhost:8081";
    static final String KEYS_STORE = "jdbcgenericavro-count-keys";
    static final String SALES_STORE = "jdbcgenericavro-aggregate-sales";

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


        final KStreamBuilder builder = new KStreamBuilder();

        Properties streamsConfiguration = new Properties();
        streamsConfiguration.put(StreamsConfig.APPLICATION_ID_CONFIG, "jdbcgenericavro-2");
        streamsConfiguration.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        streamsConfiguration.put(StreamsConfig.COMMIT_INTERVAL_MS_CONFIG, 1000);
        streamsConfiguration.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        streamsConfiguration.put(StreamsConfig.VALUE_SERDE_CLASS_CONFIG, GenericAvroSerde.class);
        streamsConfiguration.put(AbstractKafkaAvroSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG, SCHEMA_REGISTRY_URL);

        KStream<String, GenericRecord> locationsGeneric = builder.stream(INPUT_TOPIC);
        locationsGeneric.print();
        KStream<Long, Location> locations = locationsGeneric.map((k, v) -> new KeyValue<Long, Location>((Long) v.get("id"), new Location ((Long) v.get("id"), (String) v.get("name").toString(), (Long) v.get("sale")) ));
        locations.print();

        KStream<Long,Long> sales = locations.map((k, v) -> new KeyValue<Long, Long>(k, v.getSale()));

        // Count occurrences of each key
        KStream<Long, Long> countKeys = sales.groupByKey(Serdes.Long(), Serdes.Long())
            .count(KEYS_STORE)
            .toStream();
        countKeys.print();

        // Aggregate values by key
        KStream<Long,Long> salesAgg = sales.groupByKey(Serdes.Long(), Serdes.Long())
            .reduce(
                (aggValue, newValue) -> aggValue + newValue, SALES_STORE)
            .toStream();
        salesAgg.print();

        KafkaStreams streams = new KafkaStreams(builder, streamsConfiguration);
        streams.start();

        // Add shutdown hook to respond to SIGTERM and gracefully close Kafka Streams
        Runtime.getRuntime().addShutdownHook(new Thread(streams::close));

    }

}
