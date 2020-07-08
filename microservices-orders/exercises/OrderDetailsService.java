package io.confluent.examples.streams.microservices;

import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.FAIL;
import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.PASS;
import static io.confluent.examples.streams.avro.microservices.OrderValidationType.ORDER_DETAILS_CHECK;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.*;
import static java.util.Collections.singletonList;

import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.OrderState;
import io.confluent.examples.streams.avro.microservices.OrderValidation;
import io.confluent.examples.streams.avro.microservices.OrderValidationResult;
import io.confluent.examples.streams.microservices.domain.Schemas;
import io.confluent.examples.streams.utils.MonitoringInterceptorUtils;

import java.io.IOException;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Properties;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig;
import org.apache.commons.cli.*;
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
  private final ExecutorService executorService = Executors.newSingleThreadExecutor();
  private volatile boolean running;

  // Disable Exactly Once Semantics to enable Confluent Monitoring Interceptors
  private boolean eosEnabled = false;

  @Override
  public void start(final String bootstrapServers,
                    final String stateDir,
                    final Properties defaultConfig) {
    executorService.execute(() -> startService(bootstrapServers, defaultConfig));
    running = true;
    log.info("Started Service " + getClass().getSimpleName());
  }

  private void startService(final String bootstrapServers, final Properties defaultConfig) {
    startConsumer(bootstrapServers, defaultConfig);
    startProducer(bootstrapServers, defaultConfig);

    try {
      final Map<TopicPartition, OffsetAndMetadata> consumedOffsets = new HashMap<>();
      
      // TODO 2.1: subscribe the local `consumer` to a `Collections#singletonList` with the orders topic whose name is specified by `Topics.ORDERS.name()`
      // ...

      if (eosEnabled) {
        producer.initTransactions();
      }

      while (running) {
        final ConsumerRecords<String, Order> records = consumer.poll(Duration.ofMillis(100));
        if (records.count() > 0) {
          if (eosEnabled) {
            producer.beginTransaction();
          }
          for (final ConsumerRecord<String, Order> record : records) {
            final Order order = record.value();
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

  private void recordOffset(final Map<TopicPartition, OffsetAndMetadata> consumedOffsets,
                            final ConsumerRecord<String, Order> record) {
    final OffsetAndMetadata nextOffset = new OffsetAndMetadata(record.offset() + 1);
    consumedOffsets.put(new TopicPartition(record.topic(), record.partition()), nextOffset);
  }

  private ProducerRecord<String, OrderValidation> result(final Order order,
                                                         final OrderValidationResult passOrFail) {
    return new ProducerRecord<>(
        Topics.ORDER_VALIDATIONS.name(),
        order.getId(),
        new OrderValidation(order.getId(), ORDER_DETAILS_CHECK, passOrFail)
    );
  }

  private void startProducer(final String bootstrapServers, final Properties defaultConfig) {
    final Properties producerConfig = new Properties();
    producerConfig.putAll(defaultConfig);
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

  private void startConsumer(final String bootstrapServers, final Properties defaultConfig) {
    final Properties consumerConfig = new Properties();
    consumerConfig.putAll(defaultConfig);
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
    } catch (final InterruptedException e) {
      log.info("Failed to stop " + getClass().getSimpleName() + " in 1000ms");
    }
    log.info(getClass().getSimpleName() + " was stopped");
  }

  private boolean isValid(final Order order) {
    if (order.getQuantity() < 0) {
      return false;
    }
    if (order.getPrice() < 0) {
      return false;
    }
    return order.getProduct() != null;
  }

  public void setEosEnabled(final boolean value) {
    this.eosEnabled = value;
  }

  public static void main(final String[] args) throws Exception {
    final Options opts = new Options();
    opts.addOption(Option.builder("b")
            .longOpt("bootstrap-servers")
            .hasArg()
            .desc("Kafka cluster bootstrap server string (ex: broker:9092)")
            .build());
    opts.addOption(Option.builder("s")
            .longOpt("schema-registry")
            .hasArg()
            .desc("Schema Registry URL")
            .build());
    opts.addOption(Option.builder("c")
            .longOpt("config-file")
            .hasArg()
            .desc("Java properties file with configurations for Kafka Clients")
            .build());
    opts.addOption(Option.builder("t")
            .longOpt("state-dir")
            .hasArg()
            .desc("The directory for state storage")
            .build());
    opts.addOption(Option.builder("h").longOpt("help").hasArg(false).desc("Show usage information").build());

    final CommandLine cl = new DefaultParser().parse(opts, args);

    if (cl.hasOption("h")) {
      final HelpFormatter formatter = new HelpFormatter();
      formatter.printHelp("Order Details Service", opts);
      return;
    }
    final Properties defaultConfig = Optional.ofNullable(cl.getOptionValue("config-file", null))
            .map(path -> {
              try {
                return buildPropertiesFromConfigFile(path);
              } catch (final IOException e) {
                throw new RuntimeException(e);
              }
            })
            .orElse(new Properties());

    final String schemaRegistryUrl = cl.getOptionValue("schema-registry", DEFAULT_SCHEMA_REGISTRY_URL);
    defaultConfig.put(AbstractKafkaSchemaSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG, schemaRegistryUrl);
    Schemas.configureSerdes(defaultConfig);

    final OrderDetailsService service = new OrderDetailsService();
    service.start(
            cl.getOptionValue("bootstrap-servers", DEFAULT_BOOTSTRAP_SERVERS),
            cl.getOptionValue("state-dir", "/tmp/kafka-streams-examples"),
            defaultConfig);
    addShutdownHookAndBlock(service);
  }
}

