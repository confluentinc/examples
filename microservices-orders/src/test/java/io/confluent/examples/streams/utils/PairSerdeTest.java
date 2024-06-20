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

import org.apache.kafka.common.serialization.Serdes;
import org.junit.Test;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.MatcherAssert.assertThat;

public class PairSerdeTest {

  @Test
  public void shouldRoundTrip() {
    // Given
    final Pair<String, Long> pair = new Pair<>("foo", 5L);
    final String anyTopic = "ANY_TOPIC";
    final PairSerde<String, Long> pairSerde = new PairSerde<>(Serdes.String(), Serdes.Long());

    // When
    final byte[] serializedBytes = pairSerde.serializer().serialize(anyTopic, pair);
    final Pair<String, Long> deserializedPair = pairSerde.deserializer().deserialize(anyTopic, serializedBytes);

    // Then
    assertThat(deserializedPair, equalTo(pair));
  }


  @Test
  public void shouldSupportNullForX() {
    // Given
    final Pair<String, Long> pair = new Pair<>(null, 5L);
    final String anyTopic = "ANY_TOPIC";
    final PairSerde<String, Long> pairSerde = new PairSerde<>(Serdes.String(), Serdes.Long());

    // When
    final byte[] serializedBytes = pairSerde.serializer().serialize(anyTopic, pair);
    final Pair<String, Long> deserializedPair = pairSerde.deserializer().deserialize(anyTopic, serializedBytes);

    // Then
    assertThat(deserializedPair, equalTo(pair));
  }

  @Test
  public void shouldSupportNullForY() {
    // Given
    final Pair<String, Long> pair = new Pair<>("foo", null);
    final String anyTopic = "ANY_TOPIC";
    final PairSerde<String, Long> pairSerde = new PairSerde<>(Serdes.String(), Serdes.Long());

    // When
    final byte[] serializedBytes = pairSerde.serializer().serialize(anyTopic, pair);
    final Pair<String, Long> deserializedPair = pairSerde.deserializer().deserialize(anyTopic, serializedBytes);

    // Then
    assertThat(deserializedPair, equalTo(pair));
  }

  @Test
  public void shouldSupportNullForXAndY() {
    // Given
    final Pair<String, Long> pair = new Pair<>(null, null);
    final String anyTopic = "ANY_TOPIC";
    final PairSerde<String, Long> pairSerde = new PairSerde<>(Serdes.String(), Serdes.Long());

    // When
    final byte[] serializedBytes = pairSerde.serializer().serialize(anyTopic, pair);
    final Pair<String, Long> deserializedPair = pairSerde.deserializer().deserialize(anyTopic, serializedBytes);

    // Then
    assertThat(deserializedPair, equalTo(pair));
  }

  @Test
  public void shouldSupportNullReference() {
    // Given
    final Pair<String, Long> pair = null;
    final String anyTopic = "ANY_TOPIC";
    final PairSerde<String, Long> pairSerde = new PairSerde<>(Serdes.String(), Serdes.Long());

    // When
    final byte[] serializedBytes = pairSerde.serializer().serialize(anyTopic, pair);
    final Pair<String, Long> deserializedPair = pairSerde.deserializer().deserialize(anyTopic, serializedBytes);

    // Then
    assertThat(deserializedPair, equalTo(pair));
  }

}