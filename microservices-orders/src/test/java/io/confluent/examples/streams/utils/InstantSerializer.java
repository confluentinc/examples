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

import org.apache.kafka.common.serialization.Serializer;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.time.Instant;
import java.util.Map;

public class InstantSerializer implements Serializer<Instant> {

  @Override
  public void configure(final Map<String, ?> configs, final boolean isKey) {
  }

  @Override
  public byte[] serialize(final String topic, final Instant instant) {
    if (instant == null) {
      return null;
    }
    try (
      final ByteArrayOutputStream baos = new ByteArrayOutputStream();
      final DataOutputStream out = new DataOutputStream(baos)
    ) {
      final long secsSinceEpoch = instant.getEpochSecond();
      final int nanoSecsFromStartOfSecond = instant.getNano();
      out.writeLong(secsSinceEpoch);
      out.writeInt(nanoSecsFromStartOfSecond);
      return baos.toByteArray();
    } catch (final IOException e) {
      throw new RuntimeException("unable to serialize Instant", e);
    }
  }

  @Override
  public void close() {
  }

}