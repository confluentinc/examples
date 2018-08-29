package io.confluent.examples.streams.microservices;

import io.confluent.examples.streams.avro.microservices.OrderState;
import io.confluent.examples.streams.avro.microservices.Product;
import io.confluent.examples.streams.microservices.domain.Schemas;
import io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import io.confluent.examples.streams.microservices.domain.beans.OrderBean;
import io.confluent.examples.streams.microservices.util.Paths;

import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.streams.StreamsConfig;

import org.apache.kafka.common.serialization.Serdes;

import org.glassfish.jersey.client.ClientConfig;
import org.glassfish.jersey.client.ClientProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.client.Entity;
import javax.ws.rs.core.GenericType;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.concurrent.ExecutionException;

import static io.confluent.examples.streams.avro.microservices.Product.JUMPERS;
import static io.confluent.examples.streams.avro.microservices.Product.UNDERPANTS;
import static io.confluent.examples.streams.microservices.domain.beans.OrderId.id;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.MIN;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.ProductTypeSerde;
import static java.util.Arrays.asList;
import static javax.ws.rs.core.MediaType.APPLICATION_JSON_TYPE;

import javax.ws.rs.core.Response;

public class AddInventory {

  private static void sendInventory(List<KeyValue<Product, Integer>> inventory,
      Schemas.Topic<Product, Integer> topic) {

    Properties producerConfig = new Properties();
    producerConfig.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
    producerConfig.put(ProducerConfig.ACKS_CONFIG, "all");
    producerConfig.put(ProducerConfig.RETRIES_CONFIG, 0);

    ProductTypeSerde productSerde = new ProductTypeSerde();

    try (KafkaProducer<Product, Integer> stockProducer = new KafkaProducer<>(
        producerConfig,
        productSerde.serializer(),
        Serdes.Integer().serializer()))
    {
      for (KeyValue<Product, Integer> kv : inventory) {
        stockProducer.send(new ProducerRecord<>("warehouse-inventory", kv.key, kv.value))
            .get();
      }
    } catch (InterruptedException | ExecutionException e) {
      e.printStackTrace();
    }
  }

  public static void main(String [] args) throws Exception {

    final int quantityUnderpants = args.length > 0 ? Integer.valueOf(args[0]) : 20;
    final int quantityJumpers = args.length > 1 ? Integer.valueOf(args[1]) : 10;

    // Send Inventory
    List<KeyValue<Product, Integer>> inventory = asList(
        new KeyValue<>(UNDERPANTS, quantityUnderpants),
        new KeyValue<>(JUMPERS, quantityJumpers)
    );
    System.out.printf("Send inventory to %s\n", Topics.WAREHOUSE_INVENTORY);
    sendInventory(inventory, Topics.WAREHOUSE_INVENTORY);

  }

}
