import io.confluent.kafka.serializers.json.KafkaJsonSchemaSerializer;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.SneakyThrows;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.Properties;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
class CloudEvent<T> {
    private String id;
    private URI source;
    private String specVersion;
    private String type;
    private String datacontenttype;
    private URI dataschema;
    private String subject;
    private long timestamp;
    private T data;
}

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

public class SampleProducer {

    @SneakyThrows
    private static Properties producerProperties() throws IOException {
        Properties prop = new Properties();
        ClassLoader loader = Thread.currentThread().getContextClassLoader();
        InputStream stream = loader.getResourceAsStream("producer.properties");
        prop.load(stream);
        return prop;
    }

    public static void main(String [] args) {
        // produceGenericCloudEvent();
        produceNonGenericCloudEvent();
    }

    @SneakyThrows
    private static void produceGenericCloudEvent() {
        KafkaProducer<String, CloudEvent<Order>> kafkaProducer = new KafkaProducer<>(producerProperties());
        Order order = Order.builder().productID(UUID.randomUUID()).customerID(UUID.randomUUID()).timestamp(System.currentTimeMillis()).build();
        CloudEvent<Order> orderEvent = CloudEvent.<Order>builder()
                .data(order)
                .id(UUID.randomUUID().toString())
                .timestamp(System.currentTimeMillis())
                .source(new URI("https://my.producer.application.org"))
                .specVersion("1.0.1")
                .build();
        var result = kafkaProducer.send(new ProducerRecord<>("order-topic", orderEvent.getId(), orderEvent));
        System.err.println(result.get().toString());
    }

    @SneakyThrows
    private static void produceNonGenericCloudEvent() {
        KafkaProducer<String, OrderCloudEvent> kafkaProducer = new KafkaProducer<>(producerProperties());
        Order order = Order.builder().productID(UUID.randomUUID()).customerID(UUID.randomUUID()).timestamp(System.currentTimeMillis()).build();
        OrderCloudEvent orderCloudEvent = OrderCloudEvent.builder()
                .data(order)
                .id(UUID.randomUUID().toString())
                .specVersion("1.0.1")
                .source(new URI("https://my.producer.application.org"))
                .build();
        var result = kafkaProducer.send(
                new ProducerRecord<>("order-cloud-events", orderCloudEvent.getId(), orderCloudEvent)
        );
        System.err.println(result.get().toString());
    }
}
