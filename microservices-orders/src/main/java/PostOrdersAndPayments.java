package io.confluent.examples.streams.microservices;

import io.confluent.examples.streams.avro.microservices.OrderState;
import io.confluent.examples.streams.avro.microservices.Product;
import io.confluent.examples.streams.avro.microservices.Payment;
import io.confluent.examples.streams.microservices.domain.Schemas;
import io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import io.confluent.examples.streams.microservices.domain.beans.OrderBean;
import io.confluent.examples.streams.microservices.util.Paths;
import io.confluent.examples.streams.utils.MonitoringInterceptorUtils;

import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.streams.StreamsConfig;

import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.StringSerializer;
import io.confluent.kafka.serializers.AbstractKafkaAvroSerDeConfig;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerde;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerializer;

import org.glassfish.jersey.client.ClientConfig;
import org.glassfish.jersey.client.ClientProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.client.Entity;
import javax.ws.rs.core.GenericType;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Properties;
import java.util.Collections;
import java.util.concurrent.ExecutionException;
import java.util.Random;

import static io.confluent.examples.streams.avro.microservices.Product.JUMPERS;
import static io.confluent.examples.streams.avro.microservices.Product.UNDERPANTS;
import static io.confluent.examples.streams.microservices.domain.beans.OrderId.id;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.MIN;
import static javax.ws.rs.core.MediaType.APPLICATION_JSON_TYPE;

import javax.ws.rs.core.Response;

public class PostOrdersAndPayments {

  private static GenericType<OrderBean> newBean() {
    return new GenericType<OrderBean>() {
    };
  }

  private static void sendPayment(String id, Payment payment,
      Schemas.Topic<String, Payment> topic) {

    //System.out.printf("-----> id: %s, payment: %s\n", id, payment);

    final SpecificAvroSerializer<Payment> paymentSerializer = new SpecificAvroSerializer<>();
    final boolean isKeySerde = false;
    paymentSerializer.configure(
        Collections.singletonMap(AbstractKafkaAvroSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG, "http://localhost:8081"),
        isKeySerde);

    final Properties producerConfig = new Properties();
    producerConfig.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
    producerConfig.put(ProducerConfig.ACKS_CONFIG, "all");
    producerConfig.put(ProducerConfig.RETRIES_CONFIG, 0);
    producerConfig.put(ProducerConfig.CLIENT_ID_CONFIG, "payment-generator");
    MonitoringInterceptorUtils.maybeConfigureInterceptorsProducer(producerConfig);

    KafkaProducer<String, Payment> paymentProducer = new KafkaProducer<String, Payment>(producerConfig, new StringSerializer(), paymentSerializer);

    ProducerRecord<String, Payment> record = new ProducerRecord<String, Payment>("payments", id, payment);
    paymentProducer.send(record);
    paymentProducer.close();
  }

  public static void main(String [] args) throws Exception {

    final int NUM_CUSTOMERS = 6;
    final List<Product> productTypeList = Arrays.asList(Product.JUMPERS, Product.UNDERPANTS, Product.STOCKINGS);
    final Random randomGenerator = new Random();

    final int restPort = args.length > 0 ? Integer.valueOf(args[0]) : 5432;
    System.out.printf("restPort: %d\n", restPort);

    OrderBean returnedOrder;
    Paths path = new Paths("localhost", restPort == 0 ? 5432 : restPort);

    final ClientConfig clientConfig = new ClientConfig();
    clientConfig.property(ClientProperties.CONNECT_TIMEOUT, 60000)
        .property(ClientProperties.READ_TIMEOUT, 60000);
    Client client = ClientBuilder.newClient(clientConfig);

    // send one order every 1 second
    int i = 1;
    while (true) {

      int randomCustomerId = randomGenerator.nextInt(NUM_CUSTOMERS);
      Product randomProduct = productTypeList.get(randomGenerator.nextInt(productTypeList.size()));

      //OrderBean inputOrder = new OrderBean(id(i), Long.valueOf(randomCustomerId), OrderState.CREATED, Product.JUMPERS, 1, 1d);
      OrderBean inputOrder = new OrderBean(id(i), Long.valueOf(randomCustomerId), OrderState.CREATED, randomProduct, 1, 1d);

      // POST order to OrdersService
      System.out.printf("Posting order to: %s   .... ", path.urlPost());
      Response response = client.target(path.urlPost())
          .request(APPLICATION_JSON_TYPE)
          .post(Entity.json(inputOrder));
      System.out.printf("Response: %s \n", response.getStatus());

      // GET the bean back explicitly
      System.out.printf("Getting order from: %s   .... ", path.urlGet(i));
      returnedOrder = client.target(path.urlGet(i))
          .queryParam("timeout", MIN / 2)
          .request(APPLICATION_JSON_TYPE)
          .get(newBean());

      if (!inputOrder.equals(returnedOrder)) {
        System.out.printf("Posted order %d does not equal returned order: %s\n", i, returnedOrder.toString());
      } else {
        System.out.printf("Posted order %d equals returned order: %s\n", i, returnedOrder.toString());
      }

      // Send payment
      Payment payment = new Payment("Payment:1234", id(i), "CZK", 1000.00d);
      sendPayment(payment.getId(), payment, Topics.PAYMENTS);
  
      // GET order, assert that it is Validated
      //returnedOrder = client.target(path.urlGetValidated(i)).queryParam("timeout", MIN)
      //  .request(APPLICATION_JSON_TYPE).get(newBean());
      //assertThat(returnedOrder).isEqualTo(new OrderBean(
      //    inputOrder.getId(),
      //    inputOrder.getCustomerId(),
      //    OrderState.VALIDATED,
      //    inputOrder.getProduct(),
      //    inputOrder.getQuantity(),
      //    inputOrder.getPrice()
      //));

      Thread.sleep(1000L);
      i++;
    }
  }

}
