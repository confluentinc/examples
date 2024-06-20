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

import org.apache.kafka.common.serialization.Deserializer;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.serialization.Serializer;

import java.util.Comparator;
import java.util.Map;
import java.util.PriorityQueue;

public class PriorityQueueSerde<T> implements Serde<PriorityQueue<T>> {

  private final Serde<PriorityQueue<T>> inner;

  public PriorityQueueSerde(final Comparator<T> comparator, final Serde<T> avroSerde) {
    inner = Serdes.serdeFrom(new PriorityQueueSerializer<>(comparator, avroSerde.serializer()),
                             new PriorityQueueDeserializer<>(comparator, avroSerde.deserializer()));
  }

  @Override
  public Serializer<PriorityQueue<T>> serializer() {
    return inner.serializer();
  }

  @Override
  public Deserializer<PriorityQueue<T>> deserializer() {
    return inner.deserializer();
  }

  @Override
  public void configure(final Map<String, ?> configs, final boolean isKey) {
    inner.serializer().configure(configs, isKey);
    inner.deserializer().configure(configs, isKey);
  }

  @Override
  public void close() {
    inner.serializer().close();
    inner.deserializer().close();
  }

}