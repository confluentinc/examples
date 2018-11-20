package io.confluent.examples.streams.microservices;

import static io.confluent.examples.streams.microservices.domain.Schemas.Topics.CUSTOMERS;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics.ORDERS;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics.PAYMENTS;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.MIN;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.addShutdownHookAndBlock;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.baseStreamsConfig;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.parseArgsAndConfigure;

import io.confluent.examples.streams.avro.microservices.Customer;
import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.Payment;

import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.GlobalKTable;
import org.apache.kafka.streams.kstream.JoinWindows;
import org.apache.kafka.streams.kstream.Joined;
import org.apache.kafka.streams.kstream.KStream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * A very simple service which sends emails. Order and Payment streams are joined
 * using a window. The result is then joined to a lookup table of Customers.
 * Finally an email is sent for each resulting tuple.
 */
public class EmailService implements Service {

  private static final Logger log = LoggerFactory.getLogger(EmailService.class);
  private final String SERVICE_APP_ID = getClass().getSimpleName();

  private KafkaStreams streams;
  private Emailer emailer;

  public EmailService(Emailer emailer) {
    this.emailer = emailer;
  }

  @Override
  public void start(final String bootstrapServers, final String stateDir) {
    streams = processStreams(bootstrapServers, stateDir);
    streams.cleanUp(); //don't do this in prod as it clears your state stores
    streams.start();
    log.info("Started Service " + SERVICE_APP_ID);
  }

  private KafkaStreams processStreams(final String bootstrapServers, final String stateDir) {

    final StreamsBuilder builder = new StreamsBuilder();

    //Create the streams/tables for the join
    final KStream<String, Order> orders = builder.stream(ORDERS.name(),
        Consumed.with(ORDERS.keySerde(), ORDERS.valueSerde()));

    final KStream<String, Payment> payments_original = builder.stream(PAYMENTS.name(),
        Consumed.with(PAYMENTS.keySerde(), PAYMENTS.valueSerde()));

    // TODO 3.1: create a new `KStream` called `payments` from `payments_original`, using `KStream#selectKey` to rekey on order id specified by `payment.getOrderId()` instead of payment id
    // ...

    final GlobalKTable<Long, Customer> customers = builder.globalTable(CUSTOMERS.name(),
        Consumed.with(CUSTOMERS.keySerde(), CUSTOMERS.valueSerde()));

    final Joined<String, Order, Payment> serdes = Joined
        .with(ORDERS.keySerde(), ORDERS.valueSerde(), PAYMENTS.valueSerde());

    //Join the two streams and the table then send an email for each
    orders.join(payments, EmailTuple::new,
        //Join Orders and Payments streams
        JoinWindows.of(MIN), serdes)

            // TODO 3.2: do a stream-table join with the customers table, which requires three arguments:
            // 1) the GlobalKTable for the stream-table join
            // 2) customer Id, specified by `order.getCustomerId()`, using a KeyValueMapper that gets the customer id from the tuple in the record's value
            // 3) method that computes a value for the result record, in this case `EmailTuple::setCustomer`
            // ...

        //Now for each tuple send an email.
        .peek((key, emailTuple)
            -> emailer.sendEmail(emailTuple)
        );

    return new KafkaStreams(builder.build(), baseStreamsConfig(bootstrapServers, stateDir, SERVICE_APP_ID));
  }

  public static void main(String[] args) throws Exception {
    EmailService service = new EmailService(new LoggingEmailer());
    service.start(parseArgsAndConfigure(args), "/tmp/kafka-streams");
    addShutdownHookAndBlock(service);
  }

  private static class LoggingEmailer implements Emailer {

    @Override
    public void sendEmail(EmailTuple details) {
      //In a real implementation we would do something a little more useful
      log.warn("Sending an email to: \nCustomer:%s\nOrder:%s\nPayment%s", details.customer,
          details.order, details.payment);
    }
  }

  @Override
  public void stop() {
    if (streams != null) {
      streams.close();
    }
  }

  interface Emailer {
    void sendEmail(EmailTuple details);
  }

  public class EmailTuple {

    public Order order;
    public Payment payment;
    public Customer customer;

    public EmailTuple(Order order, Payment payment) {
      this.order = order;
      this.payment = payment;
    }

    EmailTuple setCustomer(Customer customer) {
      this.customer = customer;
      return this;
    }

    @Override
    public String toString() {
      return "EmailTuple{" +
          "order=" + order +
          ", payment=" + payment +
          ", customer=" + customer +
          '}';
    }
  }
}
