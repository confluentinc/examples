package io.confluent.examples.streams.microservices;

import static io.confluent.examples.streams.avro.microservices.Order.newBuilder;
import static io.confluent.examples.streams.avro.microservices.OrderState.VALIDATED;
import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.FAIL;
import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.PASS;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics.ORDERS;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics.ORDER_VALIDATIONS;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.MIN;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.addShutdownHookAndBlock;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.baseStreamsConfig;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.parseArgsAndConfigure;

import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.OrderState;
import io.confluent.examples.streams.avro.microservices.OrderValidation;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.JoinWindows;
import org.apache.kafka.streams.kstream.Joined;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.Materialized;
import org.apache.kafka.streams.kstream.Produced;
import org.apache.kafka.streams.kstream.Serialized;
import org.apache.kafka.streams.kstream.SessionWindows;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * A simple service which listens to to validation results from each of the Validation
 * services and aggregates them by order Id, triggering a pass or fail based on whether
 * all rules pass or not.
 */
public class ValidationsAggregatorService implements Service {

  private static final Logger log = LoggerFactory.getLogger(ValidationsAggregatorService.class);
  private final String SERVICE_APP_ID = getClass().getSimpleName();
  private final Consumed<String, OrderValidation> serdes1 = Consumed
      .with(ORDER_VALIDATIONS.keySerde(), ORDER_VALIDATIONS.valueSerde());
  private final Consumed<String, Order> serdes2 = Consumed.with(ORDERS.keySerde(),
      ORDERS.valueSerde());
  private final Serialized<String, OrderValidation> serdes3 = Serialized
      .with(ORDER_VALIDATIONS.keySerde(), ORDER_VALIDATIONS.valueSerde());
  private final Joined<String, Long, Order> serdes4 = Joined
      .with(ORDERS.keySerde(), Serdes.Long(), ORDERS.valueSerde());
  private final Produced<String, Order> serdes5 = Produced
      .with(ORDERS.keySerde(), ORDERS.valueSerde());
  private final Serialized<String, Order> serdes6 = Serialized
      .with(ORDERS.keySerde(), ORDERS.valueSerde());
  private final Joined<String, OrderValidation, Order> serdes7 = Joined
      .with(ORDERS.keySerde(), ORDER_VALIDATIONS.valueSerde(), ORDERS.valueSerde());

  private KafkaStreams streams;

  @Override
  public void start(final String bootstrapServers, final String stateDir) {
    streams = aggregateOrderValidations(bootstrapServers, stateDir);
    streams.cleanUp(); //don't do this in prod as it clears your state stores
    streams.start();
    log.info("Started Service " + getClass().getSimpleName());
  }

  private KafkaStreams aggregateOrderValidations(
      final String bootstrapServers,
      final String stateDir) {
    final int numberOfRules = 3; //TODO put into a KTable to make dynamically configurable

    StreamsBuilder builder = new StreamsBuilder();
    KStream<String, OrderValidation> validations = builder
        .stream(ORDER_VALIDATIONS.name(), serdes1);
    KStream<String, Order> orders = builder
        .stream(ORDERS.name(), serdes2)
        .filter((id, order) -> OrderState.CREATED.equals(order.getState()));

    //If all rules pass then validate the order
    validations
        .groupByKey(serdes3)

        // TODO 5.1: window the data using `KGroupedStream#windowedBy`, specifically using `SessionWindows.with` to define 5-minute windows
        // ...

        .aggregate(
            () -> 0L,
            (id, result, total) -> PASS.equals(result.getValidationResult()) ? total + 1 : total,
            (k, a, b) -> b == null ? a : b, //include a merger as we're using session windows.
            Materialized.with(null, Serdes.Long())
        )
        //get rid of window
        .toStream((windowedKey, total) -> windowedKey.key())
        //When elements are evicted from a session window they create delete events. Filter these.
        .filter((k1, v) -> v != null)
        //only include results were all rules passed validation
        .filter((k, total) -> total >= numberOfRules)
        //Join back to orders
        .join(orders, (id, order) ->
                //Set the order to Validated
                newBuilder(order).setState(VALIDATED).build()
            , JoinWindows.of(5 * MIN), serdes4)
        //Push the validated order into the orders topic
        .to(ORDERS.name(), serdes5);

    //If any rule fails then fail the order
    validations.filter((id, rule) -> FAIL.equals(rule.getValidationResult()))
        .join(orders, (id, order) ->
                //Set the order to Failed and bump the version on it's ID
                newBuilder(order).setState(OrderState.FAILED).build(),
            JoinWindows.of(5 * MIN), serdes7)

        //there could be multiple failed rules for each order so collapse to a single order

        // TODO 5.2: group the records by key using `KStream#groupByKey`, providing the existing Serialized instance for ORDERS
        // ...

        // TODO 5.3: use an aggregation operator `KTable#reduce` to collapse the records in this stream to a single order for a given key
        // ...

        //Push the validated order into the orders topic
        .toStream().to(ORDERS.name(), Produced.with(ORDERS.keySerde(), ORDERS.valueSerde()));

    return new KafkaStreams(builder.build(),
        baseStreamsConfig(bootstrapServers, stateDir, SERVICE_APP_ID));
  }

  @Override
  public void stop() {
    if (streams != null) {
      streams.close();
    }
  }

  public static void main(String[] args) throws Exception {
    final String bootstrapServers = parseArgsAndConfigure(args);
    ValidationsAggregatorService service = new ValidationsAggregatorService();
    service.start(bootstrapServers, "/tmp/kafka-streams");
    addShutdownHookAndBlock(service);
  }
}
