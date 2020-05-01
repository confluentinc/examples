package io.confluent.examples.clients.cloud.springboot.kafka;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class SpringbootKafkaApplication {

  // injected from application.properties
  @Value("${io.confluent.developer.config.topic.name}")
  private String topicName;

  @Value("${io.confluent.developer.config.topic.partitions}")
  private int numPartitions;

  @Value("${io.confluent.developer.config.topic.replicas}")
  private int replicas;

  @Bean
  NewTopic moviesTopic() {
    return new NewTopic(topicName, numPartitions, (short) replicas);
  }

  public static void main(final String[] args) {
    SpringApplication.run(SpringbootKafkaApplication.class, args);
  }

}
