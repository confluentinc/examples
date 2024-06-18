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
import org.apache.kafka.common.serialization.DoubleDeserializer;
import org.apache.kafka.common.serialization.LongDeserializer;

import java.util.Map;

public class PairOfDoubleAndLongDeserializer implements Deserializer<Pair<Double, Long>> {

  public PairOfDoubleAndLongDeserializer() {
  }

  final private Deserializer<Pair<Double, Long>> inner =
    new PairDeserializer<>(new DoubleDeserializer(), new LongDeserializer());

  @Override
  public void configure(final Map<String, ?> configs, final boolean isKey) {
  }

  @Override
  public Pair<Double, Long> deserialize(final String topic, final byte[] bytes) {
    return inner.deserialize(topic, bytes);
  }

  @Override
  public void close() {

  }
}