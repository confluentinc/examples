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

package io.confluent.examples.connectandstreams.javaproducer;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.LongSerializer;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import io.confluent.examples.connectandstreams.avro.Location;
import io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig;
import io.confluent.kafka.serializers.KafkaAvroSerializer;


public class Driver {

  static final String INPUT_TOPIC = "javaproducer-locations";
  static final String DEFAULT_TABLE_LOCATIONS = "/usr/local/lib/table.locations";
  static final String DEFAULT_BOOTSTRAP_SERVERS = "localhost:9092";
  static final String DEFAULT_SCHEMA_REGISTRY_URL = "http://localhost:8081";

  public static void main(final String[] args) throws Exception {

    if (args.length > 3) {
      throw new IllegalArgumentException("usage: ... "
                                         + "[<bootstrap.servers> (optional, default: " + DEFAULT_BOOTSTRAP_SERVERS
                                         + ")] "
                                         + "[<schema.registry.url> (optional, default: " + DEFAULT_SCHEMA_REGISTRY_URL
                                         + ")] "
                                         + "[<table.locations> (optional, default: " + DEFAULT_TABLE_LOCATIONS + ")] ");
    }

    final String bootstrapServers = args.length > 0 ? args[0] : DEFAULT_BOOTSTRAP_SERVERS;
    final String schemaRegistryUrl = args.length > 1 ? args[1] : DEFAULT_SCHEMA_REGISTRY_URL;
    final String tableLocations = args.length > 2 ? args[2] : DEFAULT_TABLE_LOCATIONS;

    System.out.println("Connecting to Kafka cluster via bootstrap servers " + bootstrapServers);
    System.out.println("Connecting to Confluent schema registry at " + schemaRegistryUrl);
    System.out.println("Reading locations table from file " + tableLocations);

    final List<Location> locationsList = new ArrayList<>();
    try (final BufferedReader br = new BufferedReader(new FileReader(tableLocations))) {
      String line;
      while ((line = br.readLine()) != null) {
        final String[] parts = line.split("\\|");
        locationsList.add(new Location(Long.parseLong(parts[0]), parts[1],
                                       Long.parseLong(parts[2])));
      }
    }

    final Properties props = new Properties();
    props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, LongSerializer.class);
    props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, KafkaAvroSerializer.class);
    props.put(AbstractKafkaSchemaSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG, schemaRegistryUrl);
    final KafkaProducer<Long, Location>
        locationProducer =
        new KafkaProducer<Long, Location>(props);

    locationsList.forEach(t -> {
      System.out.println("Writing location information for '" + t.getId()
                         + "' to input topic " + INPUT_TOPIC);
      final ProducerRecord<Long, Location> record = new ProducerRecord<Long, Location>(INPUT_TOPIC,
                                                                                       t.getId(), t);
      locationProducer.send(record);
    });

    locationProducer.close();

  }

}

