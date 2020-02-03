package io.confluent.examples.clients.cloud.springboot;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class SpringbootApplication {

  // inject from config
  private static String SAMPLE_TOPIC = "topic";

  @Bean
  NewTopic moviesTopic() {
    return new NewTopic(SAMPLE_TOPIC, 1, (short) 1);
  }

  public static void main(String[] args) {
    SpringApplication.run(SpringbootApplication.class, args);
  }

}
