package io.confluent.examples.streams.microservices;

import io.confluent.examples.streams.avro.microservices.Customer;
import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.Payment;
import io.confluent.examples.streams.microservices.domain.Schemas;
import io.confluent.examples.streams.microservices.util.MicroserviceTestUtils;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.test.TestUtils;
import org.junit.After;
import org.junit.BeforeClass;
import org.junit.Test;

import java.util.Collections;
import java.util.Properties;

import static io.confluent.examples.streams.avro.microservices.OrderState.CREATED;
import static io.confluent.examples.streams.avro.microservices.Product.UNDERPANTS;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import static io.confluent.examples.streams.microservices.domain.beans.OrderId.id;
import static io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG;
import static org.assertj.core.api.Assertions.assertThat;

public class EmailServiceTest extends MicroserviceTestUtils {

  private EmailService emailService;
  private volatile boolean complete;

  @BeforeClass
  public static void startKafkaCluster() throws Exception {
    if (!CLUSTER.isRunning()) {
      CLUSTER.start();
    }

    CLUSTER.createTopic(Topics.ORDERS.name());
    CLUSTER.createTopic(Topics.CUSTOMERS.name());
    CLUSTER.createTopic(Topics.PAYMENTS.name());
    final Properties config = new Properties();
    config.put(SCHEMA_REGISTRY_URL_CONFIG, CLUSTER.schemaRegistryUrl());
    Schemas.configureSerdes(config);
  }

  @After
  public void tearDown() {
    emailService.stop();
    CLUSTER.stop();
  }

  @Test
  public void shouldSendEmailWithValidContents() throws Exception {

    //Given one order, customer and payment
    final String orderId = id(0L);
    final Order order = new Order(orderId, 15L, CREATED, UNDERPANTS, 3, 5.00d);
    final Customer customer = new Customer(15L, "Franz", "Kafka", "frans@thedarkside.net", "oppression street, prague, cze", "gold");
    final Payment payment = new Payment("Payment:1234", orderId, "CZK", 1000.00d);

    emailService = new EmailService(details -> {
      assertThat(details.customer).isEqualTo(customer);
      assertThat(details.payment).isEqualTo(payment);
      assertThat(details.order).isEqualTo(order);
      complete = true;
    });

    send(Topics.CUSTOMERS, Collections.singleton(new KeyValue<>(customer.getId(), customer)));
    send(Topics.ORDERS, Collections.singleton(new KeyValue<>(order.getId(), order)));
    send(Topics.PAYMENTS, Collections.singleton(new KeyValue<>(payment.getId(), payment)));

    //When
    emailService.start(CLUSTER.bootstrapServers(), TestUtils.tempDirectory().getPath(), new Properties());

    //Then
    TestUtils.waitForCondition(() -> complete, 60000L, "Email was never sent.");
  }
}
