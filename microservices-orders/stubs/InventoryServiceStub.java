package io.confluent.examples.streams.microservices;

import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.Joined;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.kstream.Produced;
import org.apache.kafka.streams.kstream.Transformer;
import org.apache.kafka.streams.processor.ProcessorContext;
import org.apache.kafka.streams.state.KeyValueStore;
import org.apache.kafka.streams.state.StoreBuilder;
import org.apache.kafka.streams.state.Stores;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;

import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.OrderState;
import io.confluent.examples.streams.avro.microservices.OrderValidation;
import io.confluent.examples.streams.avro.microservices.Product;
import io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import io.confluent.examples.streams.microservices.util.MicroserviceUtils;

import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.FAIL;
import static io.confluent.examples.streams.avro.microservices.OrderValidationResult.PASS;
import static io.confluent.examples.streams.avro.microservices.OrderValidationType.INVENTORY_CHECK;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.addShutdownHookAndBlock;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.parseArgsAndConfigure;

/**
 * This service validates incoming orders to ensure there is sufficient stock to
 * fulfill them. This validation process considers both the inventory in the warehouse
 * as well as a set "reserved" items which is maintained by this service. Reserved
 * items are those that are in the warehouse, but have been allocated to a pending
 * order.
 * <p>
 * Currently there is nothing implemented that decrements the reserved items. This
 * would happen, inside this service, in response to an order being shipped.
 */
public class InventoryServiceStub implements Service {

  private static final Logger log = LoggerFactory.getLogger(InventoryServiceStub.class);
  public static final String INVENTORY_SERVICE_APP_ID = "inventory-service-Stub";
  public static final String RESERVED_STOCK_STORE_NAME = "store-of-reserved-stock";
  private KafkaStreams streams;

  @Override
  public void start(final String bootstrapServers, final String stateDir) {
    streams = processStreams(bootstrapServers, stateDir);
    streams.cleanUp(); //don't do this in prod as it clears your state stores
    // STUDENT: start the streams application
    log.info("Started Service " + getClass().getSimpleName());
  }

  @Override
  public void stop() {
    if (streams != null) {
      streams.close();
    }
  }

  private KafkaStreams processStreams(final String bootstrapServers, final String stateDir) {

    //Latch onto instances of the orders and inventory topics
    StreamsBuilder builder = new StreamsBuilder();
    KStream<String, Order> orders = builder
      .stream(Topics.ORDERS.name(),
        Consumed.with(Topics.ORDERS.keySerde(), Topics.ORDERS.valueSerde()));
    // STUDENT: create a 'KTable<Product, Integer> warehouseInventory' object
    // that reads for the WAREHOUSE_INVENTORY topic (similar to as done for ORDERS topic above)

    //Create a store to reserve inventory whilst the order is processed.
    //This will be prepopulated from Kafka before the service starts processing
    StoreBuilder reservedStock = Stores
      .keyValueStoreBuilder(Stores.persistentKeyValueStore(RESERVED_STOCK_STORE_NAME),
        Topics.WAREHOUSE_INVENTORY.keySerde(), Serdes.Long())
      .withLoggingEnabled(new HashMap<>());
    builder.addStateStore(reservedStock);

    //First change orders stream to be keyed by Product (so we can join with warehouse inventory)
    orders.selectKey((id, order) -> order.getProduct())
      //Limit to newly created orders
      .filter((id, order) -> OrderState.CREATED.equals(order.getState()))
      //Join Orders to Inventory so we can compare each order to its corresponding stock value
      .join(warehouseInventory, KeyValue::new, Joined.with(Topics.WAREHOUSE_INVENTORY.keySerde(),
        Topics.ORDERS.valueSerde(), Serdes.Integer()))
      //Validate the order based on how much stock we have both in the warehouse and locally 'reserved' stock
      .transform(InventoryValidator::new, RESERVED_STOCK_STORE_NAME)
      // STUDENT: Push the result into the Order Validations topic using the '.to()' method

    return new KafkaStreams(builder.build(),
      MicroserviceUtils.baseStreamsConfig(bootstrapServers, stateDir, INVENTORY_SERVICE_APP_ID));
  }

  private static class InventoryValidator implements
    Transformer<Product, KeyValue<Order, Integer>, KeyValue<String, OrderValidation>> {

    private KeyValueStore<Product, Long> reservedStocksStore;

    @Override
    @SuppressWarnings("unchecked")
    public void init(ProcessorContext context) {
      reservedStocksStore = (KeyValueStore<Product, Long>) context
        .getStateStore(RESERVED_STOCK_STORE_NAME);
    }

    @Override
    public KeyValue<String, OrderValidation> transform(final Product productId,
                                                       final KeyValue<Order, Integer> orderAndStock) {
      //Process each order/inventory pair one at a time
      OrderValidation validated;
      Order order = orderAndStock.key;
      Integer warehouseStockCount = orderAndStock.value;

      //Look up locally 'reserved' stock from our state store
      Long reserved = reservedStocksStore.get(order.getProduct());
      if (reserved == null) {
        reserved = 0L;
      }

      //If there is enough stock available (considering both warehouse inventory and reserved stock) validate the order
      if (warehouseStockCount - reserved - order.getQuantity() >= 0) {
        //reserve the stock by adding it to the 'reserved' store
        reservedStocksStore.put(order.getProduct(), reserved + order.getQuantity());
        //validate the order
        validated = new OrderValidation(order.getId(), INVENTORY_CHECK, PASS);
      } else {
        // STUDENT: create a new OrderValidation, similar to above, but with a 'FAIL' result
      }
      return KeyValue.pair(validated.getOrderId(), validated);
    }

    @Override
    public void close() {
    }
  }

  public static void main(String[] args) throws Exception {
    InventoryServiceStub service = new InventoryServiceStub();
    service.start(parseArgsAndConfigure(args), "/tmp/kafka-streams");
    addShutdownHookAndBlock(service);
  }
}
