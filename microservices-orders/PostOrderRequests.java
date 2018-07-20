package io.confluent.examples.streams.microservices;

import io.confluent.examples.streams.avro.microservices.OrderState;
import io.confluent.examples.streams.avro.microservices.Product;
import io.confluent.examples.streams.microservices.domain.Schemas;
import io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import io.confluent.examples.streams.microservices.domain.beans.OrderBean;
import io.confluent.examples.streams.microservices.util.Paths;

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
import java.lang.Math;

import static io.confluent.examples.streams.avro.microservices.Product.JUMPERS;
import static io.confluent.examples.streams.avro.microservices.Product.UNDERPANTS;
import static io.confluent.examples.streams.microservices.domain.beans.OrderId.id;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.MIN;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.ProductTypeSerde;
import static java.util.Arrays.asList;
import static javax.ws.rs.core.MediaType.APPLICATION_JSON_TYPE;

import javax.ws.rs.core.Response;

public class PostOrderRequests {

  private static GenericType<OrderBean> newBean() {
    return new GenericType<OrderBean>() {
    };
  }

  public static void main(String [] args) throws Exception {

    final int NUM_CUSTOMERS = 6;

    final int restPort = args.length > 0 ? Integer.valueOf(args[0]) : 5432;
    System.out.printf("restPort: %d\n", restPort);

    OrderBean returnedOrder;
    Paths path = new Paths("localhost", restPort == 0 ? 5432 : restPort);

    final ClientConfig clientConfig = new ClientConfig();
    clientConfig.property(ClientProperties.CONNECT_TIMEOUT, 60000)
        .property(ClientProperties.READ_TIMEOUT, 60000);
    Client client = ClientBuilder.newClient(clientConfig);

    // send 2000 orders, one every 1000 milliseconds
    for (int i = 0; i < 2000; i++) {

      int randomCustomerId = (int)(Math.random() * NUM_CUSTOMERS + 1);

      OrderBean inputOrder = new OrderBean(id(i), Long.valueOf(randomCustomerId), OrderState.CREATED, Product.JUMPERS, 1, 1d);

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
    }
  }

}
