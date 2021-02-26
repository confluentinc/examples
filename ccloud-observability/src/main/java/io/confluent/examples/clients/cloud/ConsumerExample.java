/**
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
package io.confluent.examples.clients.cloud;

import io.confluent.examples.clients.cloud.model.PageviewRecord;
import java.util.concurrent.TimeUnit;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import io.confluent.kafka.serializers.KafkaJsonDeserializerConfig;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Properties;

public class ConsumerExample {

  public static void main(final String[] args) throws Exception {
    if (args.length != 2) {
      System.out.println("Please provide command line arguments: configPath topic");
      System.exit(1);
    }

    final String topic = args[1];

    // Load properties from a local configuration file
    // Create the configuration file (e.g. at '$HOME/.confluent/java.config') with configuration parameters
    // to connect to your Kafka cluster, which can be on your local host, Confluent Cloud, or any other cluster.
    // Follow these instructions to create this file: https://docs.confluent.io/platform/current/tutorials/examples/clients/docs/java.html

    final Properties props = loadConfig(args[0]);

    // Add additional properties.
    props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");
    props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, "io.confluent.kafka.serializers.KafkaJsonDeserializer");
    props.put(KafkaJsonDeserializerConfig.JSON_VALUE_TYPE, PageviewRecord.class);
    props.put(ConsumerConfig.GROUP_ID_CONFIG, "demo-cloud-observability-1");
    props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

    // Create consumer
    final Consumer<String, PageviewRecord> consumer = new KafkaConsumer<String, PageviewRecord>(props);
    consumer.subscribe(Arrays.asList(topic));

    // Poll for messages
    Long total_count = 0L;
    try {
      while (true) {
        ConsumerRecords<String, PageviewRecord> records = consumer.poll(100);
        for (ConsumerRecord<String, PageviewRecord> record : records) {
          total_count++;
          if (total_count % 1000 == 0) {
            System.out.printf("Consumer reached %d, sleep to simulate consumer skip heartbeat", total_count);
            Thread.sleep(3000);
          }
        }
      }
    } finally {
      consumer.close();
    }
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
