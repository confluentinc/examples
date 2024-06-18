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

import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.IOException;
import java.time.Instant;
import java.util.Map;

public class InstantDeserializer implements Deserializer<Instant> {

  @Override
  public void configure(final Map<String, ?> configs, final boolean isKey) {
  }

  @Override
  public Instant deserialize(final String topic, final byte[] bytes) {
    if (bytes == null || bytes.length == 0) {
      return null;
    }
    final Instant instant;
    try (final DataInputStream in = new DataInputStream(new ByteArrayInputStream(bytes))) {
      final long secsSinceEpoch = in.readLong();
      final int nanoSecsFromStartOfSecond = in.readInt();
      instant = Instant.ofEpochSecond(secsSinceEpoch, nanoSecsFromStartOfSecond);
    } catch (final IOException e) {
      throw new RuntimeException("Unable to deserialize Pair", e);
    }
    return instant;
  }

  @Override
  public void close() {
  }

}