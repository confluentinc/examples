package io.confluent.examples.streams.microservices.util;

import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.OrderValidation;
import io.confluent.examples.streams.avro.microservices.Product;
import io.confluent.examples.streams.kafka.EmbeddedSingleNodeKafkaCluster;
import io.confluent.examples.streams.microservices.domain.Schemas;
import io.confluent.examples.streams.microservices.domain.Schemas.Topic;
import io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import kafka.server.KafkaConfig;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.Deserializer;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.test.TestUtils;
import org.junit.AfterClass;
import org.junit.ClassRule;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.ws.rs.ServerErrorException;
import javax.ws.rs.client.Entity;
import javax.ws.rs.client.Invocation;
import javax.ws.rs.core.GenericType;
import javax.ws.rs.core.Response;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Properties;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import static java.util.Collections.singletonList;

public class MicroserviceTestUtils {

  private static final Logger log = LoggerFactory.getLogger(MicroserviceTestUtils.class);
  private static final List<TopicTailer<?, ?>> tailers = new ArrayList<>();
  private static int consumerCounter;

  @ClassRule
  public static final EmbeddedSingleNodeKafkaCluster CLUSTER = new EmbeddedSingleNodeKafkaCluster(
      new Properties() {
        {
          //Transactions need durability so the defaults require multiple nodes.
          //For testing purposes set transactions to work with a single kafka broker.
          put(KafkaConfig.TransactionsTopicReplicationFactorProp(), "1");
          put(KafkaConfig.TransactionsTopicMinISRProp(), "1");
          put(KafkaConfig.TransactionsTopicPartitionsProp(), "1");
        }
      });

  @AfterClass
  public static void stopCluster() {
    log.info("stopping cluster");
    if (CLUSTER.isRunning()) {
      CLUSTER.stop();
    }
  }

  protected static Properties producerConfig(final EmbeddedSingleNodeKafkaCluster cluster) {
    final Properties producerConfig = new Properties();
    producerConfig.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, cluster.bootstrapServers());
    producerConfig.put(ProducerConfig.ACKS_CONFIG, "all");
    producerConfig.put(ProducerConfig.RETRIES_CONFIG, 1);
    return producerConfig;
  }

  public static <K, V> List<V> read(final Schemas.Topic<K, V> topic, final int numberToRead,
                                    final String bootstrapServers) throws InterruptedException {
    return readKeyValues(topic, numberToRead, bootstrapServers).stream().map(kv -> kv.value)
        .collect(Collectors.toList());
  }

  public static <K, V> List<K> readKeys(final Schemas.Topic<K, V> topic, final int numberToRead,
                                        final String bootstrapServers) throws InterruptedException {
    return readKeyValues(topic, numberToRead, bootstrapServers).stream().map(kv -> kv.key)
        .collect(Collectors.toList());
  }

  public static <K, V> List<KeyValue<K, V>> readKeyValues(final Schemas.Topic<K, V> topic,
                                                          final int numberToRead,
                                                          final String bootstrapServers) throws InterruptedException {
    final Deserializer<K> keyDes = topic.keySerde().deserializer();
    final Deserializer<V> valDes = topic.valueSerde().deserializer();
    final String topicName = topic.name();
    return readKeysAndValues(numberToRead, bootstrapServers, keyDes, valDes, topicName);
  }

  private static <K, V> List<KeyValue<K, V>> readKeysAndValues(final int numberToRead,
                                                               final String bootstrapServers,
                                                               final Deserializer<K> keyDes,
                                                               final Deserializer<V> valDes,
                                                               final String topicName) throws InterruptedException {
    final Properties consumerConfig = new Properties();
    consumerConfig.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    consumerConfig.put(ConsumerConfig.GROUP_ID_CONFIG, "Test-Reader-" + consumerCounter++);
    consumerConfig.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

    final KafkaConsumer<K, V> consumer = new KafkaConsumer<>(consumerConfig, keyDes, valDes);
    consumer.subscribe(singletonList(topicName));

    final List<KeyValue<K, V>> actualValues = new ArrayList<>();
    TestUtils.waitForCondition(() -> {
      final ConsumerRecords<K, V> records = consumer.poll(Duration.ofMillis(100));
      for (final ConsumerRecord<K, V> record : records) {
        actualValues.add(KeyValue.pair(record.key(), record.value()));
      }
      return actualValues.size() == numberToRead;
    }, 40000, "Timed out reading orders.");
    consumer.close();
    return actualValues;
  }

  private static <K, V> void tailAllTopicsToConsole(final Schemas.Topic<K, V> topic,
                                                    final String bootstrapServers) {
    final TopicTailer<K, V> task = new TopicTailer<>(topic, bootstrapServers);
    tailers.add(task);
    Executors.newSingleThreadExecutor().execute(task);
  }

  public static void stopTailers() {
    tailers.forEach(TopicTailer::stop);
  }

  public static void tailAllTopicsToConsole(final String bootstrapServers) {
    for (final Topic<?, ?> t : Topics.ALL.values()) {
      tailAllTopicsToConsole(t, bootstrapServers);
    }
  }

  static class TopicTailer<K, V> implements Runnable {

    private boolean running = true;
    private boolean closed = false;
    private final Topic<K, V> topic;
    private final String bootstrapServers;

    public TopicTailer(final Schemas.Topic<K, V> topic, final String bootstrapServers) {
      this.topic = topic;
      this.bootstrapServers = bootstrapServers;
    }

    @Override
    public void run() {
      try {
        final Properties consumerConfig = new Properties();
        consumerConfig.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        consumerConfig.put(ConsumerConfig.GROUP_ID_CONFIG, "Test-Reader-" + consumerCounter++);
        consumerConfig.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        final KafkaConsumer<K, V> consumer = new KafkaConsumer<>(
            consumerConfig,
            topic.keySerde().deserializer(),
            topic.valueSerde().deserializer()
        );
        consumer.subscribe(singletonList(topic.name()));

        while (running) {
          final ConsumerRecords<K, V> records = consumer.poll(Duration.ofMillis(100));
          for (final ConsumerRecord<K, V> record : records) {
            log.info("Tailer[" + topic.name() + "-Offset:" + record.offset() + "]: " + record.key()
                + "->" + record.value());
          }
        }
        consumer.close();
      } finally {
        closed = true;
      }
    }

    void stop() {
      running = false;
      while (!closed) {
        try {
          Thread.sleep(200);
          log.info("Closing tailer...");
        } catch (final InterruptedException e) {
          e.printStackTrace();
        }
      }
    }
  }

  public static <K, V> void send(final Topic<K, V> topic, final KeyValue<K, V> record) {
    send(topic, Collections.singletonList(record));
  }

  public static <K, V> void send(final Topic<K, V> topic, final Collection<KeyValue<K, V>> stuff) {
    try (final KafkaProducer<K, V> producer = new KafkaProducer<>(
        producerConfig(CLUSTER),
        topic.keySerde().serializer(),
        topic.valueSerde().serializer()))
    {
      for (final KeyValue<K, V> order : stuff) {
        producer.send(new ProducerRecord<>(topic.name(), order.key, order.value)).get();
      }
    } catch (final InterruptedException | ExecutionException e) {
      e.printStackTrace();
    }
  }

  public static void sendOrders(final List<Order> orders) {
    final List<KeyValue<String, Order>> collect = orders
        .stream()
        .map(o -> new KeyValue<>(o.getId(), o))
        .collect(Collectors.toList());
    send(Topics.ORDERS, collect);
  }

  public static void sendOrderValuations(final List<OrderValidation> orderValidations) {
    final List<KeyValue<String, OrderValidation>> collect = orderValidations
        .stream()
        .map(o -> new KeyValue<>(o.getOrderId(), o))
        .collect(Collectors.toList());
    send(Topics.ORDER_VALIDATIONS, collect);
  }

  public static void sendInventory(final List<KeyValue<Product, Integer>> inventory,
                                   final Schemas.Topic<Product, Integer> topic) {
    try (final KafkaProducer<Product, Integer> stockProducer = new KafkaProducer<>(
        producerConfig(CLUSTER),
        topic.keySerde().serializer(),
        Schemas.Topics.WAREHOUSE_INVENTORY.valueSerde().serializer()))
    {
      for (final KeyValue<Product, Integer> kv : inventory) {
        stockProducer.send(new ProducerRecord<>(Topics.WAREHOUSE_INVENTORY.name(), kv.key, kv.value))
            .get();
      }
    } catch (final InterruptedException | ExecutionException e) {
      e.printStackTrace();
    }
  }

  public static <T> T getWithRetries(final Invocation.Builder builder,
                                     final GenericType<T> genericType,
                                     final int numberOfRetries) {
    final AtomicInteger retriesRemaining = new AtomicInteger(numberOfRetries);
    while (true) {
      try {
        return builder.get(genericType);
      } catch (final ServerErrorException exception) {
        if (exception.getMessage().contains("504") && retriesRemaining.getAndDecrement() > 0) {
          continue;
        }
        throw exception;
      }
    }
  }

  public static <T> T getWithRetries(final Invocation.Builder builder,
                                     final Class<T> clazz,
                                     final int numberOfRetries) {
    final AtomicInteger retriesRemaining = new AtomicInteger(numberOfRetries);
    while (true) {
      try {
        return builder.get(clazz);
      } catch (final ServerErrorException exception) {
        if (exception.getMessage().contains("504") && retriesRemaining.getAndDecrement() > 0) {
          continue;
        }
        throw exception;
      }
    }
  }

  public static <T> Response postWithRetries(final Invocation.Builder builder,
                                             final Entity<T> entity,
                                             final int numberOfRetries) {
    final AtomicInteger retriesRemaining = new AtomicInteger(numberOfRetries);
    while (true) {
      try {
        return builder.post(entity);
      } catch (final ServerErrorException exception) {
        if (exception.getMessage().contains("504") && retriesRemaining.getAndDecrement() > 0) {
          continue;
        }
        throw exception;
      }
    }
  }
}
