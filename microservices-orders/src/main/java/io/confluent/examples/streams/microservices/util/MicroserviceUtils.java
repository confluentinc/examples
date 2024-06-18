package io.confluent.examples.streams.microservices.util;

import io.confluent.examples.streams.avro.microservices.Product;
import io.confluent.examples.streams.microservices.Service;
import io.confluent.examples.streams.microservices.domain.Schemas;
import io.confluent.examples.streams.utils.MonitoringInterceptorUtils;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.Deserializer;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serializer;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.state.RocksDBConfigSetter;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.servlet.ServletHolder;
import org.glassfish.jersey.jackson.JacksonFeature;
import org.glassfish.jersey.server.ResourceConfig;
import org.glassfish.jersey.servlet.ServletContainer;
import org.rocksdb.Options;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.ws.rs.container.AsyncResponse;
import javax.ws.rs.core.Response;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.TimeUnit;

public class MicroserviceUtils {

  private static final Logger log = LoggerFactory.getLogger(MicroserviceUtils.class);
  public static final String DEFAULT_BOOTSTRAP_SERVERS = "localhost:9092";
  public static final String DEFAULT_SCHEMA_REGISTRY_URL = "http://localhost:8081";

  public static Properties buildPropertiesFromConfigFile(final String configFile) throws IOException {
    if (!Files.exists(Paths.get(configFile))) {
      throw new IOException(configFile + " not found.");
    }
    final Properties properties = new Properties();
    try (InputStream inputStream = new FileInputStream(configFile)) {
      properties.load(inputStream);
    }
    return properties;
  }

  public static Properties baseStreamsConfig(final String bootstrapServers,
                                             final String stateDir,
                                             final String appId,
                                             final Properties defaultConfig) {
    return baseStreamsConfig(bootstrapServers, stateDir, appId, false, defaultConfig);
  }

  public static Properties baseStreamsConfigEOS(final String bootstrapServers,
                                                final String stateDir,
                                                final String appId,
                                                final Properties defaultConfig) {
    return baseStreamsConfig(bootstrapServers, stateDir, appId, true, defaultConfig);
  }

  public static Properties baseStreamsConfig(final String bootstrapServers,
                                             final String stateDir,
                                             final String appId,
                                             final boolean enableEOS,
                                             final Properties defaultConfig) {

    final Properties config = new Properties();
    config.putAll(defaultConfig);
    // Workaround for a known issue with RocksDB in environments where you have only 1 cpu core.
    config.put(StreamsConfig.ROCKSDB_CONFIG_SETTER_CLASS_CONFIG, CustomRocksDBConfig.class);
    config.put(StreamsConfig.APPLICATION_ID_CONFIG, appId);
    config.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    config.put(StreamsConfig.STATE_DIR_CONFIG, stateDir);
    config.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
    config.put(StreamsConfig.PROCESSING_GUARANTEE_CONFIG,
            enableEOS ? "exactly_once" : "at_least_once");
    config.put(StreamsConfig.COMMIT_INTERVAL_MS_CONFIG, 1); //commit as fast as possible
    config.put(StreamsConfig.consumerPrefix(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG), 30000);
    MonitoringInterceptorUtils.maybeConfigureInterceptorsStreams(config);
    return config;
  }

  public static class CustomRocksDBConfig implements RocksDBConfigSetter {

    @Override
    public void setConfig(final String storeName, final Options options,
        final Map<String, Object> configs) {
      // Workaround: We must ensure that the parallelism is set to >= 2.  There seems to be a known
      // issue with RocksDB where explicitly setting the parallelism to 1 causes issues (even though
      // 1 seems to be RocksDB's default for this configuration).
      final int compactionParallelism = Math.max(Runtime.getRuntime().availableProcessors(), 2);
      // Set number of compaction threads (but not flush threads).
      options.setIncreaseParallelism(compactionParallelism);
    }

    @Override
    public void close(final String storeName, final Options options) {

    }
  }

  //Streams doesn't provide an Enum serdes so just create one here.
  public static final class ProductTypeSerde implements Serde<Product> {

    @Override
    public void configure(final Map<String, ?> map, final boolean b) {
    }

    @Override
    public void close() {
    }

    @Override
    public Serializer<Product> serializer() {
      return new Serializer<Product>() {
        @Override
        public void configure(final Map<String, ?> map, final boolean b) {
        }

        @Override
        public byte[] serialize(final String topic, final Product pt) {
          return pt.toString().getBytes(StandardCharsets.UTF_8);
        }

        @Override
        public void close() {
        }
      };
    }

    @Override
    public Deserializer<Product> deserializer() {
      return new Deserializer<Product>() {
        @Override
        public void configure(final Map<String, ?> map, final boolean b) {
        }

        @Override
        public Product deserialize(final String topic, final byte[] bytes) {
          return Product.valueOf(new String(bytes, StandardCharsets.UTF_8));
        }

        @Override
        public void close() {
        }
      };
    }
  }

  public static void setTimeout(final long timeout, final AsyncResponse asyncResponse) {
    asyncResponse.setTimeout(timeout, TimeUnit.MILLISECONDS);
    asyncResponse.setTimeoutHandler(resp -> resp.resume(
        Response.status(Response.Status.GATEWAY_TIMEOUT)
            .entity("HTTP GET timed out after " + timeout + " ms\n")
            .build()));
  }

  public static Server startJetty(final int port, final Object binding) {
    final ServletContextHandler context = new ServletContextHandler(ServletContextHandler.SESSIONS);
    context.setContextPath("/");

    final Server jettyServer = new Server(port);
    jettyServer.setHandler(context);

    final ResourceConfig rc = new ResourceConfig();
    rc.register(binding);
    rc.register(JacksonFeature.class);

    final ServletContainer sc = new ServletContainer(rc);
    final ServletHolder holder = new ServletHolder(sc);
    context.addServlet(holder, "/*");

    try {
      jettyServer.start();
    } catch (final Exception e) {
      throw new RuntimeException(e);
    }
    log.info("Listening on " + jettyServer.getURI());
    return jettyServer;
  }

  public static <T> KafkaProducer startProducer(final String bootstrapServers,
                                                final Schemas.Topic<String, T> topic,
                                                final Properties defaultConfig) {
    final Properties producerConfig = new Properties();
    producerConfig.putAll(defaultConfig);
    producerConfig.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    producerConfig.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
    producerConfig.put(ProducerConfig.RETRIES_CONFIG, String.valueOf(Integer.MAX_VALUE));
    producerConfig.put(ProducerConfig.ACKS_CONFIG, "all");
    producerConfig.put(ProducerConfig.CLIENT_ID_CONFIG, "order-sender");
    MonitoringInterceptorUtils.maybeConfigureInterceptorsProducer(producerConfig);

    return new KafkaProducer<>(producerConfig,
        topic.keySerde().serializer(),
        topic.valueSerde().serializer());
  }

  public static void addShutdownHookAndBlock(final Service service) throws InterruptedException {
    Thread.currentThread().setUncaughtExceptionHandler((t, e) -> service.stop());
    Runtime.getRuntime().addShutdownHook(new Thread(() -> {
      try {
        service.stop();
      } catch (final Exception ignored) {
      }
    }));
    Thread.currentThread().join();
  }
}
