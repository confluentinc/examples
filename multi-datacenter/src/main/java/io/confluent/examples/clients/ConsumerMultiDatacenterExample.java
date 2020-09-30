package io.confluent.examples.clients;

import io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import io.confluent.kafka.serializers.KafkaAvroDeserializer;
import io.confluent.kafka.serializers.KafkaAvroDeserializerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.avro.generic.GenericRecord;
import io.confluent.monitoring.clients.interceptor.MonitoringInterceptorConfig;

import java.time.Duration;
import java.util.Arrays;
import java.util.Collections;
import java.util.Properties;

public class ConsumerMultiDatacenterExample {

    private static final String DEFAULT_TOPIC = "topic1";
    private static final String DEFAULT_BOOTSTRAP_SERVERS = "localhost:9092";
    private static final String DEFAULT_SCHEMA_REGISTRY_URL = "http://localhost:8081";
    private static final String DEFAULT_MONITORING_INTERCEPTORS_BOOTSTRAP_SERVERS = DEFAULT_BOOTSTRAP_SERVERS;

    @SuppressWarnings("InfiniteLoopStatement")
    public static void main(final String[] args) {

        final String topic = args.length > 0 ? args[0] : DEFAULT_TOPIC;
        final String bootstrapServers = args.length > 1 ? args[1] : DEFAULT_BOOTSTRAP_SERVERS;
        final String schemaRegistryUrl = args.length > 2 ? args[2] : DEFAULT_SCHEMA_REGISTRY_URL;
        final String monitoringInterceptorBootstrapServers = args.length > 3 ? args[3] : DEFAULT_MONITORING_INTERCEPTORS_BOOTSTRAP_SERVERS;

        System.out.printf("%nConsumer reading topic %s from bootstrap servers %s, with Confluent Schema Registry at %s, producing Confluent Monitoring Interceptors to %s%n%n", topic, bootstrapServers, schemaRegistryUrl, monitoringInterceptorBootstrapServers);

        final Properties props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, "java-consumer-" + topic);
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "true");
        props.put(ConsumerConfig.AUTO_COMMIT_INTERVAL_MS_CONFIG, "1000");
        props.put(AbstractKafkaSchemaSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG, schemaRegistryUrl);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, KafkaAvroDeserializer.class);

        // ConsumerTimestampsInterceptor: enables consumer applications to resume where they left off after a datacenter failover when using Confluent Replicator
        // MonitoringConsumerInterceptor: enables streams monitoring in Confluent Control Center
        props.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG, "io.confluent.connect.replicator.offsets.ConsumerTimestampsInterceptor,io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor");
        props.put(MonitoringInterceptorConfig.MONITORING_INTERCEPTOR_PREFIX + ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, monitoringInterceptorBootstrapServers);

        // Enable the embedded producer in the Consumer Timestamps Interceptor,
        // which writes to the `__consumer_timestamps` topic in the origin cluster,
        // to send Monitoring Producer Interceptors monitoring data
        props.put("timestamps.producer." + ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG, "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor");
        props.put("timestamps.producer." + MonitoringInterceptorConfig.MONITORING_INTERCEPTOR_PREFIX + ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, monitoringInterceptorBootstrapServers);

        try (final KafkaConsumer<String, GenericRecord> consumer = new KafkaConsumer<>(props)) {
            consumer.subscribe(Collections.singletonList(topic));

            while (true) {
                final ConsumerRecords<String, GenericRecord> records = consumer.poll(Duration.ofMillis(100));
                for (final ConsumerRecord<String, GenericRecord> record : records) {
                    final String key = record.key();
                    final GenericRecord value = record.value();
                    System.out.printf("key = %s, value = %s%n", key, value);
                }
            }

        }
    }
}
