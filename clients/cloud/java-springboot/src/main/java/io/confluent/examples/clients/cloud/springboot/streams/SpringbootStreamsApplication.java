package io.confluent.examples.clients.cloud.springboot.streams;

import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.Printed;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.kafka.annotation.EnableKafkaStreams;

import io.confluent.examples.clients.cloud.DataRecordAvro;

import static org.apache.kafka.streams.kstream.Grouped.with;

@SpringBootApplication
@EnableKafkaStreams
public class SpringbootStreamsApplication {

  @Value("${io.confluent.developer.config.topic.name}")
  private String topicName;

  public static void main(final String[] args) {
    SpringApplication.run(SpringbootStreamsApplication.class, args);
  }

  @Bean
  KStream<String, Long> countAgg(final StreamsBuilder builder) {

    final KStream<String, DataRecordAvro> stream = builder.stream(topicName);
    final KStream<String, Long> countAgg = stream
        .map((key, value) -> new KeyValue<>(key, value.getCount()))
        .groupByKey(with(Serdes.String(), Serdes.Long()))
        .reduce(Long::sum).toStream();

    countAgg.print(Printed.<String, Long>toSysOut().withLabel("Running count"));
    return countAgg;
  }

}
