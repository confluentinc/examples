package io.confluent.examples.streams.microservices;

import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.OrderState;
import io.confluent.examples.streams.avro.microservices.Product;
import io.confluent.examples.streams.microservices.domain.Schemas;
import io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import io.confluent.examples.streams.microservices.domain.beans.OrderBean;
import io.confluent.examples.streams.microservices.util.MicroserviceTestUtils;
import io.confluent.examples.streams.microservices.util.Paths;

import org.apache.kafka.test.TestUtils;
import org.junit.After;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import javax.ws.rs.ServerErrorException;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.client.Entity;
import javax.ws.rs.client.Invocation;
import javax.ws.rs.core.GenericType;
import javax.ws.rs.core.Response;
import java.io.File;
import java.net.HttpURLConnection;
import java.time.Duration;
import java.util.Collections;
import java.util.Properties;

import static io.confluent.examples.streams.avro.microservices.Order.newBuilder;
import static io.confluent.examples.streams.microservices.domain.beans.OrderId.id;
import static io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG;
import static javax.ws.rs.core.MediaType.APPLICATION_JSON_TYPE;
import static org.assertj.core.api.AssertionsForClassTypes.within;
import static org.assertj.core.api.AssertionsForInterfaceTypes.assertThat;
import static org.junit.Assert.fail;

public class OrdersServiceTest extends MicroserviceTestUtils {

  private OrdersService rest;
  private OrdersService rest2;

  @BeforeClass
  public static void startKafkaCluster() {
    final Properties config = new Properties();
    config.put(SCHEMA_REGISTRY_URL_CONFIG, CLUSTER.schemaRegistryUrl());
    Schemas.configureSerdes(config);
  }

  @After
  public void shutdown() {
    if (rest != null) {
      rest.stop();
      rest.cleanLocalState();
    }
    if (rest2 != null) {
      rest2.stop();
      rest2.cleanLocalState();
    }
  }

  @Before
  public void prepareKafkaCluster() throws Exception {
    CLUSTER.deleteTopicsAndWait(60000, Topics.ORDERS.name(), "OrdersService-orders-store-changelog");
    CLUSTER.createTopic(Topics.ORDERS.name());

    final Properties config = new Properties();
    config.put(SCHEMA_REGISTRY_URL_CONFIG, CLUSTER.schemaRegistryUrl());

    Schemas.configureSerdes(config);
  }

  @Test
  public void shouldPostOrderAndGetItBack() {
    final OrderBean bean = new OrderBean(id(1L), 2L, OrderState.CREATED, Product.JUMPERS, 10, 100d);

    final Client client = ClientBuilder.newClient();

    //Given a rest service
    rest = new OrdersService("localhost");
    rest.start(CLUSTER.bootstrapServers(), TestUtils.tempDirectory().getPath(), new Properties());
    final Paths paths = new Paths("localhost", rest.port());

    //When we POST an order
    final Response response = postWithRetries(
      client.target(paths.urlPost()).request(APPLICATION_JSON_TYPE),
      Entity.json(bean),
      5);

    //Then
    assertThat(response.getStatus()).isEqualTo(HttpURLConnection.HTTP_CREATED);

    //When GET the bean back via it's location
    Invocation.Builder builder = client
      .target(response.getLocation())
      .queryParam("timeout", Duration.ofSeconds(30).toMillis())
      .request(APPLICATION_JSON_TYPE);

    OrderBean returnedBean = getWithRetries(builder, newBean(), 5);

    //Then it should be the bean we PUT
    assertThat(returnedBean).isEqualTo(bean);

    //When GET the bean back explicitly
    builder = client
      .target(paths.urlGet(1))
      .queryParam("timeout", Duration.ofSeconds(30).toMillis())
      .request(APPLICATION_JSON_TYPE);

    returnedBean = getWithRetries(builder, newBean(), 5);

    //Then it should be the bean we PUT
    assertThat(returnedBean).isEqualTo(bean);
  }


  @Test
  public void shouldGetValidatedOrderOnRequest() {
    final Order orderV1 = new Order(id(1L), 3L, OrderState.CREATED, Product.JUMPERS, 10, 100d);
    final OrderBean beanV1 = OrderBean.toBean(orderV1);

    final Client client = ClientBuilder.newClient();

    //Given a rest service
    rest = new OrdersService("localhost");
    rest.start(CLUSTER.bootstrapServers(), TestUtils.tempDirectory().getPath(), new Properties());
    final Paths paths = new Paths("localhost", rest.port());

    //When we post an order
    postWithRetries(client.target(paths.urlPost()).request(APPLICATION_JSON_TYPE), Entity.json(beanV1), 5);

    //Simulate the order being validated
    MicroserviceTestUtils.sendOrders(Collections.singletonList(
      newBuilder(orderV1)
        .setState(OrderState.VALIDATED)
        .build()));

    //When we GET the order from the returned location
    final Invocation.Builder builder = client
      .target(paths.urlGetValidated(beanV1.getId()))
      .queryParam("timeout", Duration.ofSeconds(30).toMillis())
      .request(APPLICATION_JSON_TYPE);

    final OrderBean returnedBean = getWithRetries(builder, newBean(), 5);

    //Then status should be Validated
    assertThat(returnedBean.getState()).isEqualTo(OrderState.VALIDATED);
  }

  @Test
  public void shouldTimeoutGetIfNoResponseIsFound() {
    final Client client = ClientBuilder.newClient();

    //Start the rest interface
    rest = new OrdersService("localhost");
    rest.start(CLUSTER.bootstrapServers(), TestUtils.tempDirectory().getPath(), new Properties());
    final Paths paths = new Paths("localhost", rest.port());

    final Invocation.Builder builder = client
      .target(paths.urlGet(1))
      .queryParam("timeout", Duration.ofMillis(100).toMillis()) //Lower the request timeout
      .request(APPLICATION_JSON_TYPE);

    //Then GET order should timeout
    try {
      getWithRetries(builder, newBean(), 0); // no retries to fail fast
      fail("Request should have failed as materialized view has not been updated");
    } catch (final ServerErrorException e) {
      assertThat(e.getMessage()).isEqualTo("HTTP 504 Gateway Timeout");
    }
  }

  @Test
  public void shouldGetOrderByIdWhenOnDifferentHost() {
    final OrderBean order = new OrderBean(id(1L), 4L, OrderState.VALIDATED, Product.JUMPERS, 10, 100d);
    final Client client = ClientBuilder.newClient();

    //Given two rest servers on different ports
    rest = new OrdersService("localhost");
    rest.start(
            CLUSTER.bootstrapServers(),
            TestUtils.tempDirectory().getPath() + File.separator + "instance-1",
            new Properties()
    );
    final Paths paths1 = new Paths("localhost", rest.port());
    rest2 = new OrdersService("localhost");
    rest2.start(
            CLUSTER.bootstrapServers(),
            TestUtils.tempDirectory().getPath() + File.separator + "instance-2",
            new Properties()
    );
    final Paths paths2 = new Paths("localhost", rest2.port());

    //And one order
    postWithRetries(client.target(paths1.urlPost()).request(APPLICATION_JSON_TYPE), Entity.json(order), 5);

    //When GET to rest1
    Invocation.Builder builder = client
      .target(paths1.urlGet(order.getId()))
      .queryParam("timeout", Duration.ofSeconds(30).toMillis())
      .request(APPLICATION_JSON_TYPE);
    OrderBean returnedOrder = getWithRetries(builder, newBean(), 5);

    //Then we should get the order back
    assertThat(returnedOrder).isEqualTo(order);

    //When GET to rest2
    builder = client
      .target(paths2.urlGet(order.getId()))
      .queryParam("timeout", Duration.ofSeconds(30).toMillis())
      .request(APPLICATION_JSON_TYPE);
    returnedOrder = getWithRetries(builder, newBean(), 5);

    //Then we should get the order back also
    assertThat(returnedOrder).isEqualTo(order);
  }

  private GenericType<OrderBean> newBean() {
    return new GenericType<OrderBean>() {};
  }
}
