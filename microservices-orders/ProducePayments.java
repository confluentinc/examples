package io.confluent.examples.streams.microservices;

import java.util.Arrays;
import java.util.Properties;

import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringSerializer;
import io.confluent.kafka.serializers.AbstractKafkaAvroSerDeConfig;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerializer;
import java.util.Collections;

import io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import static io.confluent.examples.streams.microservices.domain.beans.OrderId.id;
import static io.confluent.examples.streams.avro.microservices.OrderState.CREATED;
import static io.confluent.examples.streams.avro.microservices.Product.UNDERPANTS;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics.PAYMENTS;
import io.confluent.examples.streams.avro.microservices.Order;
import io.confluent.examples.streams.avro.microservices.Payment;

public class ProducePayments {

    public static void main(String[] args) throws Exception {

        final SpecificAvroSerializer<Payment> mySerializer = new SpecificAvroSerializer<>();
        final boolean isKeySerde = false;
        mySerializer.configure(
            Collections.singletonMap(AbstractKafkaAvroSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG, "http://localhost:8081"),
            isKeySerde);

        final Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.RETRIES_CONFIG, 0);
        KafkaProducer<String, Payment> producer = new KafkaProducer<String, Payment>(props, new StringSerializer(), mySerializer);

        for (int i = 1; i < 2001; i++) {
           String orderId = id(0L);
           Order order = new Order(orderId, 15L, CREATED, UNDERPANTS, 3, 5.00d);
           Payment payment = new Payment("Payment:1234", orderId, "CZK", 1000.00d);
           ProducerRecord<String, Payment> record = new ProducerRecord<String, Payment>("payments", payment.getId(), payment);
           producer.send(record);
           Thread.sleep(1000L);
        };

        producer.close();
   }

}

