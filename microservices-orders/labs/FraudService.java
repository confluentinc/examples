package io.confluent.examples.streams.microservices;

import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.OrderState;
import io.confluent.examples.streams.avro.microservices.OrderValidation;
import io.confluent.examples.streams.avro.microservices.OrderValue;
import io.confluent.examples.streams.microservices.domain.Schemas;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.kstream.Materialized;
import org.apache.kafka.streams.kstream.Produced;
import org.apache.kafka.streams.kstream.Serialized;
import org.apache.kafka.streams.kstream.SessionWindows;
import org.apache.kafka.streams.kstream.Windowed;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Properties;

import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.FAIL;
import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.PASS;
import static io.confluent.examples.streams.avro.microservices.OrderValidationType.FRAUD_CHECK;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics.ORDERS;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics.ORDER_VALIDATIONS;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.addShutdownHookAndBlock;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.baseStreamsConfig;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.parseArgsAndConfigure;


/**
 * This service searches for potentially fraudulent transactions by calculating the total value of
 * orders for a customer within a time period, then checks to see if this is over a configured
 * limit. <p> i.e. if(SUM(order.value, 5Mins) > $5000) GroupBy customer -> Fail(orderId) else
 * Pass(orderId)
 */
public class FraudService implements Service {

  private static final Logger log = LoggerFactory.getLogger(FraudService.class);
  private final String SERVICE_APP_ID = getClass().getSimpleName();

  private static final int FRAUD_LIMIT = 2000;
  private static final long MIN = 60 * 1000L;
  private KafkaStreams streams;

  @Override
  public void start(final String bootstrapServers, final String stateDir) {
    streams = processStreams(bootstrapServers, stateDir);
    streams.cleanUp(); //don't do this in prod as it clears your state stores
    streams.start();
    log.info("Started Service " + getClass().getSimpleName());
  }

  private KafkaStreams processStreams(final String bootstrapServers, final String stateDir) {

    //Latch onto instances of the orders and inventory topics
    StreamsBuilder builder = new StreamsBuilder();
    KStream<String, Order> orders = builder
        .stream(ORDERS.name(), Consumed.with(ORDERS.keySerde(), ORDERS.valueSerde()))

        // TODO 4.1: filter this stream to include only orders in "CREATED" state, i.e., it should satisfy the predicate `OrderState.CREATED.equals(order.getState())`
        // ...

    //Create an aggregate of the total value by customer and hold it with the order. We use session windows to
    // detect periods of activity.
    KTable<Windowed<Long>, OrderValue> aggregate = orders
        .groupBy((id, order) -> order.getCustomerId(), Serialized.with(Serdes.Long(), ORDERS.valueSerde()))
        .windowedBy(SessionWindows.with(60 * MIN))
        .aggregate(OrderValue::new,
            //Calculate running total for each customer within this window
            (custId, order, total) -> new OrderValue(order,
                total.getValue() + order.getQuantity() * order.getPrice()),
            (k, a, b) -> simpleMerge(a, b), //include a merger as we're using session windows.
            Materialized.with(null, Schemas.ORDER_VALUE_SERDE));

    //Ditch the windowing and rekey
    KStream<String, OrderValue> ordersWithTotals = aggregate
        .toStream((windowedKey, orderValue) -> windowedKey.key())
        .filter((k, v) -> v != null)//When elements are evicted from a session window they create delete events. Filter these out.
        .selectKey((id, orderValue) -> orderValue.getOrder().getId());

    //Now branch the stream into two, for pass and fail, based on whether the windowed total is over Fraud Limit

    // TODO 4.2: create a `KStream<String, OrderValue>` array from the `ordersWithTotals` stream by branching the records based on `OrderValue#getValue`
    // 1. First branched stream: FRAUD_CHECK will fail for predicate where order value >= FRAUD_LIMIT
    // 2. Second branched stream: FRAUD_CHECK will pass for predicate where order value < FRAUD_LIMIT
    // ...

    forks[0].mapValues(
        orderValue -> new OrderValidation(orderValue.getOrder().getId(), FRAUD_CHECK, FAIL))
        .to(ORDER_VALIDATIONS.name(), Produced
            .with(ORDER_VALIDATIONS.keySerde(), ORDER_VALIDATIONS.valueSerde()));

    forks[1].mapValues(
        orderValue -> new OrderValidation(orderValue.getOrder().getId(), FRAUD_CHECK, PASS))
        .to(ORDER_VALIDATIONS.name(), Produced
            .with(ORDER_VALIDATIONS.keySerde(), ORDER_VALIDATIONS.valueSerde()));

    //disable caching to ensure a complete aggregate changelog. This is a little trick we need to apply
    //as caching in Kafka Streams will conflate subsequent updates for the same key. Disabling caching ensures
    //we get a complete "changelog" from the aggregate(...) step above (i.e. every input event will have a
    //corresponding output event.
    Properties props = baseStreamsConfig(bootstrapServers, stateDir, SERVICE_APP_ID);
    props.setProperty(StreamsConfig.CACHE_MAX_BYTES_BUFFERING_CONFIG, "0");

    return new KafkaStreams(builder.build(), props);
  }

  private OrderValue simpleMerge(OrderValue a, OrderValue b) {
    return new OrderValue(b.getOrder(), (a == null ? 0D : a.getValue()) + b.getValue());
  }

  public static void main(String[] args) throws Exception {
    FraudService service = new FraudService();
    service.start(parseArgsAndConfigure(args), "/tmp/kafka-streams");
    addShutdownHookAndBlock(service);
  }

  @Override
  public void stop() {
    if (streams != null) {
      streams.close();
    }
  }

}
