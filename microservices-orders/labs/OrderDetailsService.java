package io.confluent.examples.streams.microservices;

import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.FAIL;
import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.PASS;
import static io.confluent.examples.streams.avro.microservices.OrderValidationType.ORDER_DETAILS_CHECK;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.addShutdownHookAndBlock;
import static java.util.Collections.singletonList;

import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.OrderState;
import io.confluent.examples.streams.avro.microservices.OrderValidation;
import io.confluent.examples.streams.avro.microservices.OrderValidationResult;
import io.confluent.examples.streams.microservices.util.MicroserviceUtils;
import io.confluent.examples.streams.utils.MonitoringInterceptorUtils;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.TopicPartition;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Validates the details of each order.
 * - Is the quantity positive?
 * - Is there a customerId
 * - etc...
 * <p>
 * This service could be built with Kafka Streams but we've used a Producer/Consumer pair
 * including the integration with Kafka's Exactly Once feature (Transactions) to demonstrate
 * this other style of building event driven services. Care needs to be taken with this approach
 * as in the current release multi-node support is not provided for the transactional consumer
 * (but it is supported inside Kafka Streams)
 */
public class OrderDetailsService implements Service {

  private static final Logger log = LoggerFactory.getLogger(OrderDetailsService.class);

  private final String CONSUMER_GROUP_ID = getClass().getSimpleName();
  private KafkaConsumer<String, Order> consumer;
  private KafkaProducer<String, OrderValidation> producer;
  private ExecutorService executorService = Executors.newSingleThreadExecutor();
  private volatile boolean running;

  // Disable Exactly Once Semantics to enable Confluent Monitoring Interceptors
  private boolean eosEnabled = false;

  @Override
  public void start(final String bootstrapServers, final String stateDir) {
    executorService.execute(() -> startService(bootstrapServers));
    running = true;
    log.info("Started Service " + getClass().getSimpleName());
  }

  private void startService(String bootstrapServers) {
    startConsumer(bootstrapServers);
    startProducer(bootstrapServers);

    try {
      Map<TopicPartition, OffsetAndMetadata> consumedOffsets = new HashMap<>();

      // TODO 2.1: subscribe the local `consumer` to a `Collections#singletonList` with the orders topic whose name is specified by `Topics.ORDERS.name()`
      // ...

      if (eosEnabled) {
        producer.initTransactions();
      }

      while (running) {
        ConsumerRecords<String, Order> records = consumer.poll(100);
        if (records.count() > 0) {
          if (eosEnabled) {
            producer.beginTransaction();
          }
          for (ConsumerRecord<String, Order> record : records) {
            Order order = record.value();
            if (OrderState.CREATED.equals(order.getState())) {
              //Validate the order then send the result (but note we are in a transaction so
              //nothing will be "seen" downstream until we commit the transaction below)

              // TODO 2.2: validate the order using `OrderDetailsService#isValid` and save the validation result to type `OrderValidationResult`
              // ...

              // TODO 2.3: create a new record using `OrderDetailsService#result()` that takes the order and validation result
              // ...

              // TODO 2.4: produce the newly created record using the existing `producer`
              // ...

              if (eosEnabled) {
                recordOffset(consumedOffsets, record);
              }
            }
          }
          if (eosEnabled) {
            producer.sendOffsetsToTransaction(consumedOffsets, CONSUMER_GROUP_ID);
            producer.commitTransaction();
          }
        }
      }
    } finally {
      close();
    }
  }

  private void recordOffset(Map<TopicPartition, OffsetAndMetadata> consumedOffsets,
      ConsumerRecord<String, Order> record) {
    OffsetAndMetadata nextOffset = new OffsetAndMetadata(record.offset() + 1);
    consumedOffsets.put(new TopicPartition(record.topic(), record.partition()), nextOffset);
  }

  private ProducerRecord<String, OrderValidation> result(Order order,
      OrderValidationResult passOrFail) {
    return new ProducerRecord<>(
        Topics.ORDER_VALIDATIONS.name(),
        order.getId(),
        new OrderValidation(order.getId(), ORDER_DETAILS_CHECK, passOrFail)
    );
  }

  private void startProducer(String bootstrapServers) {
    Properties producerConfig = new Properties();
    producerConfig.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    if (eosEnabled) {
      producerConfig.put(ProducerConfig.TRANSACTIONAL_ID_CONFIG, "OrderDetailsServiceInstance1");
    }
    producerConfig.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
    producerConfig.put(ProducerConfig.RETRIES_CONFIG, String.valueOf(Integer.MAX_VALUE));
    producerConfig.put(ProducerConfig.ACKS_CONFIG, "all");
    producerConfig.put(ProducerConfig.CLIENT_ID_CONFIG, "order-details-service-producer");
    MonitoringInterceptorUtils.maybeConfigureInterceptorsProducer(producerConfig);

    producer = new KafkaProducer<>(producerConfig,
        Topics.ORDER_VALIDATIONS.keySerde().serializer(),
        Topics.ORDER_VALIDATIONS.valueSerde().serializer());
  }

  private void startConsumer(String bootstrapServers) {
    Properties consumerConfig = new Properties();
    consumerConfig.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    consumerConfig.put(ConsumerConfig.GROUP_ID_CONFIG, CONSUMER_GROUP_ID);
    consumerConfig.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
    consumerConfig.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, !eosEnabled);
    consumerConfig.put(ConsumerConfig.CLIENT_ID_CONFIG, "order-details-service-consumer");
    MonitoringInterceptorUtils.maybeConfigureInterceptorsConsumer(consumerConfig);

    consumer = new KafkaConsumer<>(consumerConfig,
        Topics.ORDERS.keySerde().deserializer(),
        Topics.ORDERS.valueSerde().deserializer());
  }

  private void close() {
    if (producer != null) {
      producer.close();
    }
    if (consumer != null) {
      consumer.close();
    }
  }

  @Override
  public void stop() {
    running = false;
    try {
      executorService.awaitTermination(1000, TimeUnit.MILLISECONDS);
    } catch (InterruptedException e) {
      log.info("Failed to stop " + getClass().getSimpleName() + " in 1000ms");
    }
    log.info(getClass().getSimpleName() + " was stopped");
  }

  private boolean isValid(Order order) {
    if (order.getCustomerId() == null) {
      return false;
    }
    if (order.getQuantity() < 0) {
      return false;
    }
    if (order.getPrice() < 0) {
      return false;
    }
    return order.getProduct() != null;
  }

  public void setEosEnabled(boolean value) {
    this.eosEnabled = value;
  }

  public static void main(String[] args) throws Exception {
    OrderDetailsService service = new OrderDetailsService();
    service.start(MicroserviceUtils.parseArgsAndConfigure(args), "/tmp/kafka-streams");
    addShutdownHookAndBlock(service);
  }
}
