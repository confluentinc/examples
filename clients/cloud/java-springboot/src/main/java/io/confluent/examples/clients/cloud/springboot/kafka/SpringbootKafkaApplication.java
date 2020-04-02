package io.confluent.examples.clients.cloud.springboot.kafka;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ResourceBanner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.core.io.ClassPathResource;

@SpringBootApplication
public class SpringbootKafkaApplication {

  // injected from config
  @Value("${io.confluent.developer.config.topic.name}")
  private String topicName;

  @Value("${io.confluent.developer.config.topic.partitions}")
  private int numPartitions;

  @Value("${io.confluent.developer.config.topic.replicas}")
  private final int replicas = 1;
  
  @Bean
  NewTopic moviesTopic() {
    return new NewTopic(topicName, numPartitions, (short) replicas);
  }

  public static void main(final String[] args) {
    SpringApplication.run(SpringbootKafkaApplication.class, args);
  }

}
