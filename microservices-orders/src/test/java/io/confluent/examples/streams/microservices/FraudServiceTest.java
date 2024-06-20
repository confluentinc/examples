package io.confluent.examples.streams.microservices;

import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.OrderValidation;
import io.confluent.examples.streams.microservices.domain.Schemas;
import io.confluent.examples.streams.microservices.util.MicroserviceTestUtils;

import org.apache.kafka.test.TestUtils;
import org.junit.After;
import org.junit.BeforeClass;
import org.junit.Test;

import java.util.List;
import java.util.Properties;

import static io.confluent.examples.streams.avro.microservices.OrderState.CREATED;
import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.FAIL;
import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.PASS;
import static io.confluent.examples.streams.avro.microservices.OrderValidationType.FRAUD_CHECK;
import static io.confluent.examples.streams.avro.microservices.Product.JUMPERS;
import static io.confluent.examples.streams.avro.microservices.Product.UNDERPANTS;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import static io.confluent.examples.streams.microservices.domain.beans.OrderId.id;
import static io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG;
import static java.util.Arrays.asList;
import static org.assertj.core.api.Assertions.assertThat;

public class FraudServiceTest extends MicroserviceTestUtils {

  private FraudService fraudService;

  @BeforeClass
  public static void startKafkaCluster() throws Exception {
    if (!CLUSTER.isRunning()) {
      CLUSTER.start();
    }

    CLUSTER.createTopic(Topics.ORDERS.name());
    CLUSTER.createTopic(Topics.ORDER_VALIDATIONS.name());
    final Properties config = new Properties();
    config.put(SCHEMA_REGISTRY_URL_CONFIG, CLUSTER.schemaRegistryUrl());
    Schemas.configureSerdes(config);
  }

  @After
  public void tearDown() {
    fraudService.stop();
    CLUSTER.stop();
  }

  @Test
  public void shouldValidateWhetherOrderAmountExceedsFraudLimitOverWindow() throws Exception {
    //Given
    fraudService = new FraudService();

    final List<Order> orders = asList(
        new Order(id(0L), 0L, CREATED, UNDERPANTS, 3, 5.00d),
        new Order(id(1L), 0L, CREATED, JUMPERS, 1, 75.00d),
        new Order(id(2L), 1L, CREATED, JUMPERS, 1, 75.00d),
        new Order(id(3L), 1L, CREATED, JUMPERS, 1, 75.00d),
        new Order(id(4L), 1L, CREATED, JUMPERS, 50, 75.00d),    //Should fail as over limit
        new Order(id(5L), 2L, CREATED, UNDERPANTS, 10, 100.00d),//First should pass
        new Order(id(6L), 2L, CREATED, UNDERPANTS, 10, 100.00d),//Second should fail as rolling total by customer is over limit
        new Order(id(7L), 2L, CREATED, UNDERPANTS, 1, 5.00d)    //Third should fail as rolling total by customer is still over limit
    );
    sendOrders(orders);

    //When
    fraudService.start(CLUSTER.bootstrapServers(), TestUtils.tempDirectory().getPath(), new Properties());

    //Then there should be failures for the two orders that push customers over their limit.
    final List<OrderValidation> expected = asList(
        new OrderValidation(id(0L), FRAUD_CHECK, PASS),
        new OrderValidation(id(1L), FRAUD_CHECK, PASS),
        new OrderValidation(id(2L), FRAUD_CHECK, PASS),
        new OrderValidation(id(3L), FRAUD_CHECK, PASS),
        new OrderValidation(id(4L), FRAUD_CHECK, FAIL),
        new OrderValidation(id(5L), FRAUD_CHECK, PASS),
        new OrderValidation(id(6L), FRAUD_CHECK, FAIL),
        new OrderValidation(id(7L), FRAUD_CHECK, FAIL)
    );
    final List<OrderValidation> read = read(Topics.ORDER_VALIDATIONS, 8, CLUSTER.bootstrapServers());
    assertThat(read).isEqualTo(expected);
  }
}