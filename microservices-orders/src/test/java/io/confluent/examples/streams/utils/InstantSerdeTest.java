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

import org.junit.Test;

import java.time.Instant;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.MatcherAssert.assertThat;

public class InstantSerdeTest {

  @Test
  public void shouldRoundTrip() {
    // Given
    final Instant instant = Instant.ofEpochSecond(5L, 4);
    final String anyTopic = "ANY_TOPIC";
    final InstantSerde instantSerde = new InstantSerde();

    // When
    final byte[] serializedBytes = instantSerde.serializer().serialize(anyTopic, instant);
    final Instant deserializedInstant = instantSerde.deserializer().deserialize(anyTopic, serializedBytes);

    // Then
    assertThat(deserializedInstant, equalTo(instant));
  }

  @Test
  public void shouldSupportNull() {
    // Given
    final Instant instant = null;
    final String anyTopic = "ANY_TOPIC";
    final InstantSerde instantSerde = new InstantSerde();

    // When
    final byte[] serializedBytes = instantSerde.serializer().serialize(anyTopic, instant);
    final Instant deserializedInstant = instantSerde.deserializer().deserialize(anyTopic, serializedBytes);

    // Then
    assertThat(deserializedInstant, equalTo(instant));
  }

}