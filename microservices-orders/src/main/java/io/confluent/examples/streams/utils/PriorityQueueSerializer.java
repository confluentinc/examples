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
import java.util.Comparator;
import java.util.Iterator;
import java.util.Map;
import java.util.PriorityQueue;

public class PriorityQueueSerializer<T> implements Serializer<PriorityQueue<T>> {

    private final Comparator<T> comparator;
    private final Serializer<T> valueSerializer;

    public PriorityQueueSerializer(final Comparator<T> comparator, final Serializer<T> valueSerializer) {
        this.comparator = comparator;
        this.valueSerializer = valueSerializer;
    }
    @Override
    public void configure(final Map<String, ?> configs, final boolean isKey) {
        // do nothing
    }

    @Override
    public byte[] serialize(final String topic, final PriorityQueue<T> queue) {
        final int size = queue.size();
        final ByteArrayOutputStream baos = new ByteArrayOutputStream();
        final DataOutputStream out = new DataOutputStream(baos);
        final Iterator<T> iterator = queue.iterator();
        try {
            out.writeInt(size);
            while (iterator.hasNext()) {
                final byte[] bytes = valueSerializer.serialize(topic, iterator.next());
                out.writeInt(bytes.length);
                out.write(bytes);
            }
            out.close();
        } catch (final IOException e) {
            throw new RuntimeException("unable to serialize PriorityQueue", e);
        }
        return baos.toByteArray();
    }

    @Override
    public void close() {

    }
}
