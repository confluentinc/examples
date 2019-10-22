/*
 * Copyright 2019 Confluent Inc.
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

package io.confluent.examples.clients.cloud;

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

import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerializer;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerde;
import io.confluent.kafka.serializers.AbstractKafkaAvroSerDeConfig;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;

import java.util.Collections;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

public class StreamsAvroExample {

    public static void main(String[] args) throws Exception {

        if (args.length != 2) {
          System.out.println("Please provide command line arguments: configPath topic");
          System.exit(1);
        }
    
        final String topic = args[1];
    
        // Load properties from a configuration file
        // The configuration properties defined in the configuration file are assumed to include:
        //   ssl.endpoint.identification.algorithm=https
        //   sasl.mechanism=PLAIN
        //   bootstrap.servers=<CLUSTER_BOOTSTRAP_SERVER>
        //   sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="<CLUSTER_API_KEY>" password="<CLUSTER_API_SECRET>";
        //   security.protocol=SASL_SSL
        //   basic.auth.credentials.source=USER_INFO
        //   schema.registry.basic.auth.user.info=<SR_API_KEY>:<SR_API_SECRET>
        //   schema.registry.url=https://<SR ENDPOINT>
        final Properties props = loadConfig(args[0]);

        // Add additional properties.
        props.put(StreamsConfig.APPLICATION_ID_CONFIG, "demo-streams-avro-1");
        // Disable caching to print the aggregation value after each record
        props.put(StreamsConfig.CACHE_MAX_BYTES_BUFFERING_CONFIG, 0);
        props.put(StreamsConfig.REPLICATION_FACTOR_CONFIG, 3);
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        final Serde<DataRecordAvro> dataRecordAvroSerde = new SpecificAvroSerde<>();
        final boolean isKeySerde = false;
        Map<String, Object> SRconfig = new HashMap<>();
        SRconfig.put(AbstractKafkaAvroSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG, props.getProperty(AbstractKafkaAvroSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG));
        SRconfig.put("schema.registry.basic.auth.user.info", props.getProperty("schema.registry.basic.auth.user.info"));
        SRconfig.put("basic.auth.credentials.source", props.getProperty("basic.auth.credentials.source"));
        dataRecordAvroSerde.configure(
            SRconfig,
            isKeySerde);

        final StreamsBuilder builder = new StreamsBuilder();
        final KStream<String, DataRecordAvro> records = builder.stream(topic, Consumed.with(Serdes.String(), dataRecordAvroSerde));

        KStream<String,Long> counts = records.map((k, v) -> new KeyValue<String, Long>(k, v.getCount()));
        counts.print(Printed.<String,Long>toSysOut().withLabel("Consumed record"));

        // Aggregate values by key
        KStream<String,Long> countAgg = counts.groupByKey(Serialized.with(Serdes.String(), Serdes.Long()))
            .reduce(
                (aggValue, newValue) -> aggValue + newValue)
            .toStream();
        countAgg.print(Printed.<String,Long>toSysOut().withLabel("Running count"));

        KafkaStreams streams = new KafkaStreams(builder.build(), props);
        streams.start();

        // Add shutdown hook to respond to SIGTERM and gracefully close Kafka Streams
        Runtime.getRuntime().addShutdownHook(new Thread(streams::close));

    }

    public static Properties loadConfig(final String configFile) throws IOException {
      if (!Files.exists(Paths.get(configFile))) {
        throw new IOException(configFile + " not found.");
      }
      final Properties cfg = new Properties();
      try (InputStream inputStream = new FileInputStream(configFile)) {
        cfg.load(inputStream);
      }
      return cfg;
    }

}
