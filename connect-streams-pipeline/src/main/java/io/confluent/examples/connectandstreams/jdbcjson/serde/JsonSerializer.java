package io.confluent.examples.connectandstreams.jdbcjson.serde;

import com.google.gson.Gson;

import org.apache.kafka.common.serialization.Serializer;

import java.nio.charset.Charset;
import java.util.Map;

public class JsonSerializer<T> implements Serializer<T> {

  private Gson gson = new Gson();

  @Override
  public void configure(final Map<String, ?> map, final boolean b) {

  }

  @Override
  public byte[] serialize(final String topic, final T t) {
    return gson.toJson(t).getBytes(Charset.forName("UTF-8"));
  }

  @Override
  public void close() {

  }
}
