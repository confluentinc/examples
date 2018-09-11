package io.confluent.examples.streams.microservices;

import java.util.Arrays;
import java.util.Properties;

import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringSerializer;
import org.apache.kafka.common.serialization.LongSerializer;
import io.confluent.kafka.serializers.AbstractKafkaAvroSerDeConfig;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerializer;
import java.util.Collections;

import io.confluent.examples.streams.utils.MonitoringInterceptorUtils;
import io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import static io.confluent.examples.streams.microservices.domain.beans.OrderId.id;
import static io.confluent.examples.streams.avro.microservices.OrderState.CREATED;
import static io.confluent.examples.streams.avro.microservices.Product.UNDERPANTS;
import static io.confluent.examples.streams.microservices.domain.Schemas.Topics.CUSTOMERS;
import io.confluent.examples.streams.avro.microservices.Customer;

public class ProduceCustomers {

    public static void main(String[] args) throws Exception {

        final SpecificAvroSerializer<Customer> mySerializer = new SpecificAvroSerializer<>();
        final boolean isKeySerde = false;
        mySerializer.configure(
            Collections.singletonMap(AbstractKafkaAvroSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG, "http://localhost:8081"),
            isKeySerde);

        final Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.RETRIES_CONFIG, 0);
        MonitoringInterceptorUtils.maybeConfigureInterceptorsProducer(props);
        KafkaProducer<Long, Customer> producer = new KafkaProducer<Long, Customer>(props, new LongSerializer(), mySerializer);

        int i = 1;
        while (true) {
           String orderId = id(0L);
           Customer customer = new Customer(15L, "Franz", "Kafka", "frans@thedarkside.net", "oppression street, prague, cze");
           ProducerRecord<Long, Customer> record = new ProducerRecord<Long, Customer>("customers", customer.getId(), customer);
           producer.send(record);
           Thread.sleep(1000L);
           i++;
        }
   }

}

