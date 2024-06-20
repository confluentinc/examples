package io.confluent.examples.streams.microservices;

import io.confluent.examples.streams.avro.microservices.Product;
import io.confluent.examples.streams.microservices.domain.Schemas;
import io.confluent.examples.streams.microservices.domain.Schemas.Topics;
import io.confluent.examples.streams.utils.MonitoringInterceptorUtils;
import org.apache.commons.cli.*;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KeyValue;

import java.io.IOException;
import java.util.List;
import java.util.Optional;
import java.util.Properties;
import java.util.concurrent.ExecutionException;

import static io.confluent.examples.streams.avro.microservices.Product.JUMPERS;
import static io.confluent.examples.streams.avro.microservices.Product.UNDERPANTS;
import static io.confluent.examples.streams.microservices.util.MicroserviceUtils.*;
import static java.util.Arrays.asList;

public class AddInventory {

    private static void sendInventory(final List<KeyValue<Product, Integer>> inventory,
                                      final Schemas.Topic<Product, Integer> topic,
                                      final String bootstrapServers,
                                      final Properties defaultConfig) {

        final Properties producerConfig = new Properties();
        producerConfig.putAll(defaultConfig);
        producerConfig.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        producerConfig.put(ProducerConfig.ACKS_CONFIG, "all");
        producerConfig.put(ProducerConfig.RETRIES_CONFIG, 1);
        producerConfig.put(ProducerConfig.CLIENT_ID_CONFIG, "inventory-generator");
        MonitoringInterceptorUtils.maybeConfigureInterceptorsProducer(producerConfig);

        final ProductTypeSerde productSerde = new ProductTypeSerde();

        try (final KafkaProducer<Product, Integer> stockProducer = new KafkaProducer<>(
            producerConfig,
            productSerde.serializer(),
            Serdes.Integer().serializer())) {
            for (final KeyValue<Product, Integer> kv : inventory) {
                stockProducer.send(new ProducerRecord<>(topic.name(), kv.key, kv.value))
                             .get();
            }
        } catch (final InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
    }

    public static void main(final String[] args) throws Exception {

        final Options opts = new Options();
        opts.addOption(Option.builder("b")
                .longOpt("bootstrap-servers").hasArg().desc("Kafka cluster bootstrap server string").build())
             .addOption(Option.builder("c")
                .longOpt("config-file").hasArg().desc("Java properties file with configurations for Kafka Clients").build())
             .addOption(Option.builder("h")
                .longOpt("help").hasArg(false).desc("Show usage information").build())
            .addOption(Option.builder("u")
                .longOpt("underpants").hasArg().desc("Quantity of underpants to add to inventory").build())
            .addOption(Option.builder("j")
                .longOpt("jumpers").hasArg().desc("Quantity of jumpers to add to inventory").build());

        final CommandLine cl = new DefaultParser().parse(opts, args);

        if (cl.hasOption("h")) {
            final HelpFormatter formatter = new HelpFormatter();
            formatter.printHelp("Add Inventory", opts);
            return;
        }

        final int quantityUnderpants = Integer.parseInt(cl.getOptionValue("u", "20"));
        final int quantityJumpers = Integer.parseInt(cl.getOptionValue("j", "10"));

        final String bootstrapServers = cl.getOptionValue("b", DEFAULT_BOOTSTRAP_SERVERS);

        final Properties defaultConfig = Optional.ofNullable(cl.getOptionValue("config-file", null))
                .map(path -> {
                    try {
                        return buildPropertiesFromConfigFile(path);
                    } catch (final IOException e) {
                        throw new RuntimeException(e);
                    }
                })
                .orElse(new Properties());

        // Send Inventory
        final List<KeyValue<Product, Integer>> inventory = asList(
            new KeyValue<>(UNDERPANTS, quantityUnderpants),
            new KeyValue<>(JUMPERS, quantityJumpers)
        );
        System.out.printf("Send inventory to %s%n", Topics.WAREHOUSE_INVENTORY);
        sendInventory(inventory, Topics.WAREHOUSE_INVENTORY, bootstrapServers, defaultConfig);

    }

}
