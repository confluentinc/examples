package io.confluent.examples.connectandstreams.utils;

import org.apache.kafka.common.errors.SerializationException;
import org.apache.kafka.common.serialization.LongDeserializer;
import org.apache.kafka.common.serialization.LongSerializer;
import org.apache.kafka.connect.data.Schema;
import org.apache.kafka.connect.data.SchemaAndValue;
import org.apache.kafka.connect.errors.DataException;
import org.apache.kafka.connect.storage.Converter;

import java.util.Map;

public class LongConverter implements Converter {
    private final LongSerializer serializer = new LongSerializer();
    private final LongDeserializer deserializer = new LongDeserializer();

    public LongConverter() {
    }

    @Override
    public void configure(Map<String, ?> configs, boolean isKey) {
    }

    @Override
    public byte[] fromConnectData(String topic, Schema schema, Object value) {
        try {
            return serializer.serialize(topic, value == null ? null : ((Long) value));
        } catch (SerializationException e) {
            throw new DataException("Failed to serialize to a string: ", e);
        }
    }

    @Override
    public SchemaAndValue toConnectData(String topic, byte[] value) {
        try {
            return new SchemaAndValue(Schema.OPTIONAL_INT64_SCHEMA, deserializer.deserialize(topic, value));
        } catch (SerializationException e) {
            throw new DataException("Failed to deserialize long: ", e);
        }
    }
}

