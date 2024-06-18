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
import java.util.Map;

public class PairDeserializer<X, Y> implements Deserializer<Pair<X, Y>> {

  private final Deserializer<X> deserializerX;
  private final Deserializer<Y> deserializerY;

  public PairDeserializer(final Deserializer<X> deserializerX, final Deserializer<Y> deserializerY) {
    this.deserializerX = deserializerX;
    this.deserializerY = deserializerY;
  }

  @Override
  public void configure(final Map<String, ?> configs, final boolean isKey) {
  }

  @Override
  public Pair<X, Y> deserialize(final String topic, final byte[] bytes) {
    if (bytes == null || bytes.length == 0) {
      return null;
    }
    final Pair<X, Y> pair;
    try (final DataInputStream in = new DataInputStream(new ByteArrayInputStream(bytes))) {
      final short magicByte = in.readShort();
      X deserializedX = null;
      Y deserializedY = null;
      if (magicByte == 1) {
        deserializedX = readX(in, topic);
      }
      if (magicByte == 2) {
        deserializedY = readY(in, topic);
      }
      if (magicByte == 3) {
        deserializedX = readX(in, topic);
        deserializedY = readY(in, topic);
      }
      pair = new Pair<>(deserializedX, deserializedY);
    } catch (final IOException e) {
      throw new RuntimeException("Unable to deserialize Pair", e);
    }
    return pair;
  }

  private X readX(final DataInputStream in, final String topic) throws IOException {
    final int xLength = in.readInt();
    final byte[] serializedX = new byte[xLength];
    in.readFully(serializedX);
    return deserializerX.deserialize(topic, serializedX);
  }

  private Y readY(final DataInputStream in, final String topic) throws IOException {
    final int yLength = in.readInt();
    final byte[] serializedY = new byte[yLength];
    in.readFully(serializedY);
    return deserializerY.deserialize(topic, serializedY);
  }

  @Override
  public void close() {
  }

}
