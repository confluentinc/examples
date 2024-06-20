package io.confluent.examples.streams.utils;

import io.confluent.monitoring.clients.interceptor.MonitoringInterceptorConfig;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.common.config.SslConfigs;
import org.apache.kafka.streams.StreamsConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.security.sasl.Sasl;
import java.util.Optional;
import java.util.Properties;

import static io.confluent.monitoring.clients.interceptor.MonitoringInterceptorConfig.MONITORING_INTERCEPTOR_PREFIX;

/**
 * Utility helper class that will enable Monitoring Interceptors when
 * found on the classpath of a Kafka Streams application.
 *
 * More information on Confluent Monitoring Interceptors can be found here:
 * https://docs.confluent.io/current/control-center/docs/installation/clients.html#installing-interceptors
 *
 */
public class MonitoringInterceptorUtils {

    private static final String CONSUMER_INTERCEPTOR = "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor";
    private static final String PRODUCER_INTERCEPTOR = "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor";
    private static final Logger LOG = LoggerFactory.getLogger(MonitoringInterceptorUtils.class);

    private MonitoringInterceptorUtils() {
    }

    private static void addMonitoringPrefixedConfigs(final Properties config) {
        if (config.containsKey("bootstrap.servers")) {
            config.put(
                MONITORING_INTERCEPTOR_PREFIX + "bootstrap.servers",
                config.getProperty("bootstrap.servers"));
        }
        if (config.containsKey("security.protocol")) {
            config.put(
                MONITORING_INTERCEPTOR_PREFIX + "security.protocol",
                config.getProperty("security.protocol"));
        }
        if (config.containsKey(SaslConfigs.SASL_MECHANISM)) {
            config.put(
                MONITORING_INTERCEPTOR_PREFIX + SaslConfigs.SASL_MECHANISM,
                config.getProperty(SaslConfigs.SASL_MECHANISM));
        }
        if (config.containsKey(SaslConfigs.SASL_JAAS_CONFIG)) {
            config.put(
                MONITORING_INTERCEPTOR_PREFIX + SaslConfigs.SASL_JAAS_CONFIG,
                config.getProperty(SaslConfigs.SASL_JAAS_CONFIG));
        }
        if (config.containsKey(SslConfigs.SSL_ENDPOINT_IDENTIFICATION_ALGORITHM_CONFIG)) {
            config.put(
                MONITORING_INTERCEPTOR_PREFIX + SslConfigs.SSL_ENDPOINT_IDENTIFICATION_ALGORITHM_CONFIG,
                config.getProperty(SslConfigs.SSL_ENDPOINT_IDENTIFICATION_ALGORITHM_CONFIG));
        }
    }

    public static void maybeConfigureInterceptorsStreams(final Properties streamsConfig) {
        if (hasMonitoringConsumerInterceptor() && hasMonitoringProducerInterceptor()) {
            streamsConfig.put(StreamsConfig.producerPrefix(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG),
                    PRODUCER_INTERCEPTOR);
            streamsConfig.put(StreamsConfig.mainConsumerPrefix(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG),
                    CONSUMER_INTERCEPTOR);
            addMonitoringPrefixedConfigs(streamsConfig);
        }
    }

    public static void maybeConfigureInterceptorsProducer(final Properties producerConfig) {
        if (hasMonitoringProducerInterceptor()) {
            producerConfig.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, PRODUCER_INTERCEPTOR);
            addMonitoringPrefixedConfigs(producerConfig);
        }
    }

    public static void maybeConfigureInterceptorsConsumer(final Properties consumerConfig) {
         if(hasMonitoringConsumerInterceptor()) {
             consumerConfig.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG, CONSUMER_INTERCEPTOR);
             addMonitoringPrefixedConfigs(consumerConfig);
         }
    }

    private static boolean hasMonitoringProducerInterceptor() {
        return hasMonitoringInterceptor(PRODUCER_INTERCEPTOR);
    }

    private static boolean hasMonitoringConsumerInterceptor() {
        return hasMonitoringInterceptor(CONSUMER_INTERCEPTOR);
    }

    private static boolean hasMonitoringInterceptor(final String className) {
        boolean hasInterceptor = true;
        try {
            Class.forName(className);
        } catch (final ClassNotFoundException e) {
            final String interceptorTypeShortName = className.substring(className.lastIndexOf('.'));
            LOG.info("{} not found, skipping", interceptorTypeShortName);
            hasInterceptor = false;
        }
        return hasInterceptor;
    }

}
