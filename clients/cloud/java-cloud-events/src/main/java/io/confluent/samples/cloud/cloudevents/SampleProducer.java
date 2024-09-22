package io.confluent.samples.cloud.cloudevents;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.io.InputStream;
import java.net.URI;
import java.util.Properties;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
class Order {
    UUID productID;
    UUID customerID;
    long timestamp;
}

@Data
@AllArgsConstructor
@Builder
class OrderCloudEvent {
    private String id;
    private URI source;
    private String specVersion;
    private String type;
    private String datacontenttype;
    private URI dataschema;
    private String subject;
    private long timestamp;
    private Order data;
}

@Slf4j
public class SampleProducer {

    @SneakyThrows
    private static Properties producerProperties() {
        Properties prop = new Properties();
        ClassLoader loader = Thread.currentThread().getContextClassLoader();
        InputStream stream = loader.getResourceAsStream("producer.properties");
        prop.load(stream);
        return prop;
    }

    public static void main(String [] args) {
        produceNonGenericCloudEvent();
    }

    @SneakyThrows
    private static void produceNonGenericCloudEvent() {
        KafkaProducer<String, OrderCloudEvent> kafkaProducer = new KafkaProducer<>(producerProperties());
        Order order = Order.builder().productID(UUID.randomUUID()).customerID(UUID.randomUUID()).timestamp(System.currentTimeMillis()).build();
        OrderCloudEvent orderCloudEvent = OrderCloudEvent.builder()
                .data(order)
                .id(UUID.randomUUID().toString())
                .specVersion("1.0")
                .subject(UUID.randomUUID().toString())
                .type("io.confluent.samples.orders.created")
                .datacontenttype("application/json")
                .timestamp(System.currentTimeMillis())
                .source(new URI("/v1/orders"))
                .build();
        log.info(new ObjectMapper().writeValueAsString(orderCloudEvent));
        var result = kafkaProducer.send(
                new ProducerRecord<>("order-cloud-events", orderCloudEvent.getId(), orderCloudEvent)
        );
        System.err.println(result.get().toString());
    }
}
