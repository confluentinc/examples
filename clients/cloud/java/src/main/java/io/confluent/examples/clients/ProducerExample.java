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
package io.confluent.examples.clients;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Date;
import java.util.Properties;
import java.util.Random;

public class ProducerExample {
  public static void main(String[] args) throws IOException {
    if (args.length != 3) {
      System.out.println("Please provide command line arguments: configPath topic numEvents");
      System.exit(-1);
    }

    long events = Long.parseLong(args[2]);
    String topic = args[1];

    // Load properties from disk.
    Properties props = loadConfig(args[0]);

    // Add additional properties.
    props.put("acks", "all");
    props.put("retries", 200);
    props.put("batch.size", 16384);
    props.put("linger.ms", 100);
    props.put("compression.type", "lz4");
    props.put("buffer.memory", 33554432);
    props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
    props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");


    Producer<String, String> producer = new KafkaProducer<String, String>(props);

    // Produce sample data.
    Random rnd = new Random();
    for (long nEvents = 0; nEvents < events; nEvents++) {
      long runtime = new Date().getTime();
      String site = "www.example.com";
      String ip = "192.168.2." + rnd.nextInt(255);

      String record = String.format("%s,%s,%s", runtime, site, ip);

      producer.send(new ProducerRecord<>(topic, ip, record));
    }

    System.out.printf("Successfully produced %s messages to %s.\n", events, topic);

    producer.close();
  }

  public static Properties loadConfig(String configFile) throws IOException {
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
