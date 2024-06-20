package io.confluent.examples.streams.microservices.util;

public class Paths {

  private final String base;

  public Paths(final String url) {
    base = url;
  }
  public Paths(final String host, final int port) {
    base = "http://" + host + ":" + port;
  }

  public String urlGet(final int id) {
    return base + "/v1/orders/" + id;
  }

  public String urlGet(final String id) {
    return base + "/v1/orders/" + id;
  }

  public String urlGetValidated(final int id) {
    return base + "/v1/orders/" + id + "/validated";
  }

  public String urlGetValidated(final String id) {
    return base + "/v1/orders/" + id + "/validated";
  }

  public String urlPost() {
    return base + "/v1/orders/";
  }
}