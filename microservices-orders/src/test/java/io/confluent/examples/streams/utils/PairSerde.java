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

import java.util.Map;

public class PairSerde<X, Y> implements Serde<Pair<X, Y>> {

  private final Serde<Pair<X, Y>> inner;

  public PairSerde(final Serde<X> serdeX, final Serde<Y> serdeY) {
    inner = Serdes.serdeFrom(
      new PairSerializer<>(serdeX.serializer(), serdeY.serializer()),
      new PairDeserializer<>(serdeX.deserializer(), serdeY.deserializer()));
  }

  @Override
  public Serializer<Pair<X, Y>> serializer() {
    return inner.serializer();
  }

  @Override
  public Deserializer<Pair<X, Y>> deserializer() {
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