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
import java.util.Map;

public class PairSerializer<X, Y> implements Serializer<Pair<X, Y>> {

  private final Serializer<X> serializerX;
  private final Serializer<Y> serializerY;

  public PairSerializer(final Serializer<X> serializerX, final Serializer<Y> serializerY) {
    this.serializerX = serializerX;
    this.serializerY = serializerY;
  }

  @Override
  public void configure(final Map<String, ?> configs, final boolean isKey) {
  }

  @Override
  public byte[] serialize(final String topic, final Pair<X, Y> pair) {
    if (pair == null) {
      return null;
    }

    try (
      final ByteArrayOutputStream baos = new ByteArrayOutputStream();
      final DataOutputStream out = new DataOutputStream(baos)
    ) {
      final byte[] serializedX = serializerX.serialize(topic, pair.x);
      final byte[] serializedY = serializerY.serialize(topic, pair.y);
      short magicByte = 0;
      if (serializedX != null) {
        magicByte += 1;
      }
      if (serializedY != null) {
        magicByte += 2;
      }
      out.writeShort(magicByte);
      if (magicByte == 1) {
        writeX(out, serializedX);
      }
      if (magicByte == 2) {
        writeY(out, serializedY);
      }
      if (magicByte == 3) {
        writeX(out, serializedX);
        writeY(out, serializedY);
      }
      return baos.toByteArray();
    } catch (final IOException e) {
      throw new RuntimeException("unable to serialize Pair", e);
    }
  }

  private void writeX(final DataOutputStream out, final byte[] serializedX) throws IOException {
    out.writeInt(serializedX.length);
    out.write(serializedX);
  }

  private void writeY(final DataOutputStream out, final byte[] serializedY) throws IOException {
    out.writeInt(serializedY.length);
    out.write(serializedY);
  }

  @Override
  public void close() {
  }

}