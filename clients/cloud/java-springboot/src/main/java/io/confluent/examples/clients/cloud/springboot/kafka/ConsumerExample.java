package io.confluent.examples.clients.cloud.springboot.kafka;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import io.confluent.examples.clients.cloud.DataRecordAvro;
import lombok.extern.log4j.Log4j2;

@Log4j2
@Component
public class ConsumerExample {

  @KafkaListener(topics = "#{'${io.confluent.developer.config.topic.name}'}")
  public void consume(final ConsumerRecord<Long, DataRecordAvro> consumerRecord) {
    log.info("received {} {}", consumerRecord.key(), consumerRecord.value());

  }
}
