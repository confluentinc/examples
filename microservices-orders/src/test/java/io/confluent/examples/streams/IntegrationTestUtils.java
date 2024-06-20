/*
 * Copyright Confluent Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package io.confluent.examples.streams;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.serialization.Deserializer;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serializer;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.state.ReadOnlyKeyValueStore;
import org.apache.kafka.streams.state.ReadOnlyWindowStore;
import org.apache.kafka.streams.state.WindowStoreIterator;
import org.apache.kafka.test.TestUtils;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.stream.Collectors;

import io.confluent.examples.streams.utils.KeyValueWithTimestamp;

/**
 * Utility functions to make integration testing more convenient.
 */
public class IntegrationTestUtils {

  private static final int UNLIMITED_MESSAGES = -1;
  private static final long DEFAULT_TIMEOUT = 30 * 1000L;

  /**
   * Returns up to `maxMessages` message-values from the topic.
   *
   * @param topic          Kafka topic to read messages from
   * @param consumerConfig Kafka consumer configuration
   * @param maxMessages    Maximum number of messages to read via the consumer.
   * @return The values retrieved via the consumer.
   */
  public static <K, V> List<V> readValues(final String topic, final Properties consumerConfig, final int maxMessages) {
    final List<KeyValue<K, V>> kvs = readKeyValues(topic, consumerConfig, maxMessages);
    return kvs.stream().map(kv -> kv.value).collect(Collectors.toList());
  }

  /**
   * Returns as many messages as possible from the topic until a (currently hardcoded) timeout is
   * reached.
   *
   * @param topic          Kafka topic to read messages from
   * @param consumerConfig Kafka consumer configuration
   * @return The KeyValue elements retrieved via the consumer.
   */
  public static <K, V> List<KeyValue<K, V>> readKeyValues(final String topic, final Properties consumerConfig) {
    return readKeyValues(topic, consumerConfig, UNLIMITED_MESSAGES);
  }

  /**
   * Returns up to `maxMessages` by reading via the provided consumer (the topic(s) to read from are
   * already configured in the consumer).
   *
   * @param topic          Kafka topic to read messages from
   * @param consumerConfig Kafka consumer configuration
   * @param maxMessages    Maximum number of messages to read via the consumer
   * @return The KeyValue elements retrieved via the consumer
   */
  public static <K, V> List<KeyValue<K, V>> readKeyValues(final String topic, final Properties consumerConfig, final int maxMessages) {
    final KafkaConsumer<K, V> consumer = new KafkaConsumer<>(consumerConfig);
    consumer.subscribe(Collections.singletonList(topic));
    final Duration pollInterval = Duration.ofMillis(100L);
    final long maxTotalPollTimeMs = 10000L;
    long totalPollTimeMs = 0;
    final List<KeyValue<K, V>> consumedValues = new ArrayList<>();
    while (totalPollTimeMs < maxTotalPollTimeMs && continueConsuming(consumedValues.size(), maxMessages)) {
      final long pollStart = System.currentTimeMillis();
      final ConsumerRecords<K, V> records = consumer.poll(pollInterval);
      final long pollEnd = System.currentTimeMillis();
      totalPollTimeMs += (pollEnd - pollStart);
      for (final ConsumerRecord<K, V> record : records) {
        consumedValues.add(new KeyValue<>(record.key(), record.value()));
      }
    }
    consumer.close();
    return consumedValues;
  }

  private static boolean continueConsuming(final int messagesConsumed, final int maxMessages) {
    return maxMessages <= 0 || messagesConsumed < maxMessages;
  }

  /**
   * Write a collection of KeyValueWithTimestamp pairs, with explicitly defined timestamps, to Kafka
   * and wait until the writes are acknowledged.
   *
   * @param topic          Kafka topic to write the data records to
   * @param records        Data records to write to Kafka
   * @param producerConfig Kafka producer configuration
   * @param <K>            Key type of the data records
   * @param <V>            Value type of the data records
   */
  public static <K, V> void produceKeyValuesWithTimestampsSynchronously(
      final String topic,
      final Collection<KeyValueWithTimestamp<K, V>> records,
      final Properties producerConfig)
      throws ExecutionException, InterruptedException {
    final Producer<K, V> producer = new KafkaProducer<>(producerConfig);
    for (final KeyValueWithTimestamp<K, V> record : records) {
      final Future<RecordMetadata> f = producer.send(
          new ProducerRecord<>(topic, null, record.timestamp, record.key, record.value));
      f.get();
    }
    producer.flush();
    producer.close();
  }

  /**
   * @param topic          Kafka topic to write the data records to
   * @param records        Data records to write to Kafka
   * @param producerConfig Kafka producer configuration
   * @param <K>            Key type of the data records
   * @param <V>            Value type of the data records
   */
  public static <K, V> void produceKeyValuesSynchronously(
      final String topic,
      final Collection<KeyValue<K, V>> records,
      final Properties producerConfig)
      throws ExecutionException, InterruptedException {
    final Collection<KeyValueWithTimestamp<K, V>> keyedRecordsWithTimestamp =
        records
            .stream()
            .map(record -> new KeyValueWithTimestamp<>(record.key, record.value, System.currentTimeMillis()))
            .collect(Collectors.toList());
    produceKeyValuesWithTimestampsSynchronously(topic, keyedRecordsWithTimestamp, producerConfig);
  }

  public static <V> void produceValuesSynchronously(
      final String topic, final Collection<V> records, final Properties producerConfig)
      throws ExecutionException, InterruptedException {
    final Collection<KeyValue<Object, V>> keyedRecords =
        records
            .stream()
            .map(record -> new KeyValue<>(null, record))
            .collect(Collectors.toList());
    produceKeyValuesSynchronously(topic, keyedRecords, producerConfig);
  }

  public static <K, V> List<KeyValue<K, V>> waitUntilMinKeyValueRecordsReceived(
      final Properties consumerConfig,
      final String topic,
      final int expectedNumRecords)
      throws InterruptedException {
    return waitUntilMinKeyValueRecordsReceived(consumerConfig, topic, expectedNumRecords, DEFAULT_TIMEOUT);
  }

  /**
   * Wait until enough data (key-value records) has been consumed.
   *
   * @param consumerConfig     Kafka Consumer configuration
   * @param topic              Topic to consume from
   * @param expectedNumRecords Minimum number of expected records
   * @param waitTime           Upper bound in waiting time in milliseconds
   * @return All the records consumed, or null if no records are consumed
   * @throws AssertionError if the given wait time elapses
   */
  public static <K, V> List<KeyValue<K, V>> waitUntilMinKeyValueRecordsReceived(final Properties consumerConfig,
                                                                                final String topic,
                                                                                final int expectedNumRecords,
                                                                                final long waitTime) throws InterruptedException {
    final List<KeyValue<K, V>> accumData = new ArrayList<>();
    final long startTime = System.currentTimeMillis();
    while (true) {
      final List<KeyValue<K, V>> readData = readKeyValues(topic, consumerConfig);
      accumData.addAll(readData);
      if (accumData.size() >= expectedNumRecords)
        return accumData;
      if (System.currentTimeMillis() > startTime + waitTime)
        throw new AssertionError("Expected " + expectedNumRecords +
            " but received only " + accumData.size() +
            " records before timeout " + waitTime + " ms");
      Thread.sleep(Math.min(waitTime, 100L));
    }
  }

  public static <V> List<V> waitUntilMinValuesRecordsReceived(final Properties consumerConfig,
                                                              final String topic,
                                                              final int expectedNumRecords) throws InterruptedException {

    return waitUntilMinValuesRecordsReceived(consumerConfig, topic, expectedNumRecords, DEFAULT_TIMEOUT);
  }

  /**
   * Wait until enough data (value records) has been consumed.
   *
   * @param consumerConfig     Kafka Consumer configuration
   * @param topic              Topic to consume from
   * @param expectedNumRecords Minimum number of expected records
   * @param waitTime           Upper bound in waiting time in milliseconds
   * @return All the records consumed, or null if no records are consumed
   * @throws AssertionError if the given wait time elapses
   */
  public static <V> List<V> waitUntilMinValuesRecordsReceived(final Properties consumerConfig,
                                                              final String topic,
                                                              final int expectedNumRecords,
                                                              final long waitTime) throws InterruptedException {
    final List<V> accumData = new ArrayList<>();
    final long startTime = System.currentTimeMillis();
    while (true) {
      final List<V> readData = readValues(topic, consumerConfig, expectedNumRecords);
      accumData.addAll(readData);
      if (accumData.size() >= expectedNumRecords)
        return accumData;
      if (System.currentTimeMillis() > startTime + waitTime)
        throw new AssertionError("Expected " + expectedNumRecords +
            " but received only " + accumData.size() +
            " records before timeout " + waitTime + " ms");
      Thread.sleep(Math.min(waitTime, 100L));
    }
  }

  /**
   * Asserts that the key-value store contains exactly the expected content and nothing more.
   *
   * @param store    the store to be validated
   * @param expected the expected contents of the store
   * @param <K>      the store's key type
   * @param <V>      the store's value type
   */
  public static <K, V> void assertThatKeyValueStoreContains(final ReadOnlyKeyValueStore<K, V> store, final Map<K, V> expected)
      throws InterruptedException {
    TestUtils.waitForCondition(() ->
            expected.keySet()
                .stream()
                .allMatch(k -> expected.get(k).equals(store.get(k))),
        30000,
        "Expected values not found in KV store");
  }

  /**
   * Asserts that the oldest available window in the window store contains the expected content.
   *
   * @param store    the store to be validated
   * @param expected the expected contents of the store
   * @param <K>      the store's key type
   * @param <V>      the store's value type
   */
  public static <K, V> void assertThatOldestWindowContains(final ReadOnlyWindowStore<K, V> store, final Map<K, V> expected)
      throws InterruptedException {
    final Instant fromBeginningOfTime = Instant.EPOCH;
    final Instant toNowInProcessingTime = Instant.now();
    TestUtils.waitForCondition(() ->
        expected.keySet().stream().allMatch(k -> {
          try (final WindowStoreIterator<V> iterator = store.fetch(k, fromBeginningOfTime, toNowInProcessingTime)) {
            if (iterator.hasNext()) {
              return expected.get(k).equals(iterator.next().value);
            }
            return false;
          }
        }),
        30000,
        "Expected values not found in WindowStore");
  }

  /**
   * Creates a map entry (for use with {@link IntegrationTestUtils#mkMap(java.util.Map.Entry[])})
   *
   * @param k   The key
   * @param v   The value
   * @param <K> The key type
   * @param <V> The value type
   * @return An entry
   */
  static <K, V> Map.Entry<K, V> mkEntry(final K k, final V v) {
    return new Map.Entry<K, V>() {
      @Override
      public K getKey() {
        return k;
      }

      @Override
      public V getValue() {
        return v;
      }

      @Override
      public V setValue(final V value) {
        throw new UnsupportedOperationException();
      }
    };
  }

  /**
   * Creates a map from a sequence of entries
   *
   * @param entries The entries to map
   * @param <K>     The key type
   * @param <V>     The value type
   * @return A map
   */
  @SafeVarargs
  static <K, V> Map<K, V> mkMap(final Map.Entry<K, V>... entries) {
    final Map<K, V> result = new LinkedHashMap<>();
    for (final Map.Entry<K, V> entry : entries) {
      result.put(entry.getKey(), entry.getValue());
    }
    return result;
  }

  /**
   * A Serializer/Deserializer/Serde implementation for use when you know the data is always null
   * @param <T> The type of the stream (you can parameterize this with any type,
   *           since we throw an exception if you attempt to use it with non-null data)
   */
  static class NothingSerde<T> implements Serializer<T>, Deserializer<T>, Serde<T> {

    @Override
    public void configure(final Map<String, ?> configuration, final boolean isKey) {}

    @Override
    public T deserialize(final String topic, final byte[] bytes) {
      if (bytes != null) {
        throw new IllegalArgumentException("Expected [" + Arrays.toString(bytes) + "] to be null.");
      } else {
        return null;
      }
    }

    @Override
    public byte[] serialize(final String topic, final T data) {
      if (data != null) {
        throw new IllegalArgumentException("Expected [" + data + "] to be null.");
      } else {
        return null;
      }
    }

    @Override
    public void close() {}

    @Override
    public Serializer<T> serializer() {
      return this;
    }

    @Override
    public Deserializer<T> deserializer() {
      return this;
    }
  }
}
