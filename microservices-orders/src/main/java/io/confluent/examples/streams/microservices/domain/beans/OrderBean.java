package io.confluent.examples.streams.microservices.domain.beans;

import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.OrderState;
import io.confluent.examples.streams.avro.microservices.Product;

import java.util.Objects;

/**
 * Simple DTO used by the REST interface
 */
public class OrderBean {

  private String id;
  private long customerId;
  private OrderState state;
  private Product product;
  private int quantity;
  private double price;

  public OrderBean() {

  }

  public OrderBean(final String id, final long customerId, final OrderState state, final Product product, final int quantity,
                   final double price) {
    this.id = id;
    this.customerId = customerId;
    this.state = state;
    this.product = product;
    this.quantity = quantity;
    this.price = price;
  }

  public String getId() {
    return id;
  }

  public long getCustomerId() {
    return customerId;
  }

  public OrderState getState() {
    return state;
  }

  public Product getProduct() {
    return product;
  }

  public int getQuantity() {
    return quantity;
  }

  public double getPrice() {
    return price;
  }

  public void setId(final String id) {
    this.id = id;
  }

  @Override
  public boolean equals(final Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || this.getClass() != o.getClass()) {
      return false;
    }

    final OrderBean orderBean = (OrderBean) o;

    if (this.customerId != orderBean.customerId) {
      return false;
    }
    if (this.quantity != orderBean.quantity) {
      return false;
    }
    if (Double.compare(orderBean.price, this.price) != 0) {
      return false;
    }
    if (!Objects.equals(this.id, orderBean.id)) {
      return false;
    }
    if (this.state != orderBean.state) {
      return false;
    }
    return this.product == orderBean.product;

  }

  @Override
  public String toString() {
    return "OrderBean{" +
        "id='" + id + '\'' +
        ", customerId=" + customerId +
        ", state=" + state +
        ", product=" + product +
        ", quantity=" + quantity +
        ", price=" + price +
        '}';
  }

  @Override
  public int hashCode() {
    int result;
    final long temp;
    result = this.id != null ? this.id.hashCode() : 0;
    result = 31 * result + (int) (this.customerId ^ this.customerId >>> 32);
    result = 31 * result + (this.state != null ? this.state.hashCode() : 0);
    result = 31 * result + (this.product != null ? this.product.hashCode() : 0);
    result = 31 * result + this.quantity;
    temp = Double.doubleToLongBits(this.price);
    result = 31 * result + (int) (temp ^ temp >>> 32);
    return result;
  }

  public static OrderBean toBean(final Order order) {
    return new OrderBean(order.getId(),
        order.getCustomerId(),
        order.getState(),
        order.getProduct(),
        order.getQuantity(),
        order.getPrice());
  }

  public static Order fromBean(final OrderBean order) {
    return new Order(order.getId(),
        order.getCustomerId(),
        order.getState(),
        order.getProduct(),
        order.getQuantity(),
        order.getPrice());
  }
}