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
package io.confluent.examples.streams.utils;

import org.apache.kafka.streams.KeyValue;

public class KeyValueWithTimestamp<K, V> extends KeyValue<K, V> {

  /**
   * Timestamp of Kafka message (milliseconds since the epoch).
   */
  public final long timestamp;

  public KeyValueWithTimestamp(final K key, final V value, final long timestamp) {
    super(key, value);
    this.timestamp = timestamp;
  }

  public KeyValueWithTimestamp(final K key, final V value) {
    this(key, value, System.currentTimeMillis());
  }

}