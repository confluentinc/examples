#!/bin/bash

############################################
# Process the Confluent Cloud configuration in $HOME/.ccloud/config
# to create delta configuration files in the destination directory
# with enabled interceptors for Streams Monitoring in Confluent Control Center
# for the following components
#
# - Confluent Schema Registry
# - KSQL Data Generator
# - KSQL server 
# - Confluent Replicator (standalone binary)
# - Confluent Control Center
# - Java
# - .NET
#
# These are _delta_ configurations, not complete component configurations
# Add them to the respective component's properties file
############################################


# Confluent Cloud configuration
CCLOUD_CONFIG=$HOME/.ccloud/config

### Glean BOOTSTRAP_SERVERS and SASL_JAAS_CONFIG (key and password) from the Confluent Cloud configuration file
BOOTSTRAP_SERVERS=$( grep "^bootstrap.server" $CCLOUD_CONFIG | awk -F'=' '{print $2;}' )
SASL_JAAS_CONFIG=$( grep "^sasl.jaas.config" $CCLOUD_CONFIG | cut -d'=' -f2- )
CLOUD_KEY=$( echo $SASL_JAAS_CONFIG | awk '{print $3}' | awk -F'"' '$0=$2' )
CLOUD_SECRET=$( echo $SASL_JAAS_CONFIG | awk '{print $4}' | awk -F'"' '$0=$2' )
echo "bootstrap.servers: $BOOTSTRAP_SERVERS"
echo "sasl.jaas.config: $SASL_JAAS_CONFIG"
echo "key: $CLOUD_KEY"
echo "secret: $CLOUD_SECRET"

# Destination directory
if [[ ! -z "$1" ]]; then
  DEST=$1
else
  DEST="delta_configs"
fi
rm -fr $DEST
mkdir -p $DEST

if [[ ! -e $CCLOUD_CONFIG ]]; then
  echo "'ccloud' is not initialized. Run 'ccloud init' and try again"
  exit 1
fi

# Build configuration file with CCloud connection parameters and
# Confluent Monitoring Interceptors for Streams Monitoring in Confluent Control Center
INTERCEPTORS_CCLOUD_CONFIG=$DEST/interceptors-ccloud.config
while read -r line
do
  echo $line >> $INTERCEPTORS_CCLOUD_CONFIG
  if [[ ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' || ${line:0:9} == 'bootstrap' ]]; then
    echo "confluent.monitoring.interceptor.$line" >> $INTERCEPTORS_CCLOUD_CONFIG
  fi
done < "$CCLOUD_CONFIG"

echo -e "\nConfluent Platform Components:"

# Confluent Schema Registry instance for Confluent Cloud
SR_CONFIG_DELTA=$DEST/schema-registry-ccloud.delta
echo "$SR_CONFIG_DELTA"
while read -r line
do
  if [[ ! -z $line && ${line:0:1} != '#' ]]; then
    if [[ ${line:0:9} == 'bootstrap' && ! "$line" =~ "SASL_SSL:" ]]; then
      # Schema Registry requires security protocol, i.e. "SASL_SSL://", in kafkastore.bootstrap.servers
      # Workaround until this issue is resolved https://github.com/confluentinc/schema-registry/issues/790
      line=${line/=/=SASL_SSL:\/\/}
      line=${line/,/,SASL_SSL:\/\/}
    fi
    echo "kafkastore.$line" >> $SR_CONFIG_DELTA
  fi
done < "$CCLOUD_CONFIG"


# Confluent Replicator for Confluent Cloud
REPLICATOR_PRODUCER_DELTA=$DEST/replicator-to-ccloud-producer.delta
echo "$REPLICATOR_PRODUCER_DELTA"
cp $INTERCEPTORS_CCLOUD_CONFIG $REPLICATOR_PRODUCER_DELTA
echo "interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor" >> $REPLICATOR_PRODUCER_DELTA
echo "request.timeout.ms=200000" >> $REPLICATOR_PRODUCER_DELTA
echo "retry.backoff.ms=500" >> $REPLICATOR_PRODUCER_DELTA

# KSQL Server runs locally and connects to Confluent Cloud
KSQL_SERVER_DELTA=$DEST/ksql-server-ccloud.delta
echo "$KSQL_SERVER_DELTA"
cp $INTERCEPTORS_CCLOUD_CONFIG $KSQL_SERVER_DELTA
echo "producer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor" >> $KSQL_SERVER_DELTA
echo "consumer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor" >> $KSQL_SERVER_DELTA
echo "ksql.streams.producer.retries=2147483647" >> $KSQL_SERVER_DELTA
echo "ksql.streams.producer.confluent.batch.expiry.ms=9223372036854775807" >> $KSQL_SERVER_DELTA
echo "ksql.streams.producer.request.timeout.ms=300000" >> $KSQL_SERVER_DELTA
echo "ksql.streams.producer.max.block.ms=9223372036854775807" >> $KSQL_SERVER_DELTA
echo "ksql.streams.replication.factor=3" >> $KSQL_SERVER_DELTA
echo "ksql.sink.replicas=3" >> $KSQL_SERVER_DELTA

# KSQL DataGen for Confluent Cloud
KSQL_DATAGEN_DELTA=$DEST/ksql-datagen.delta
echo "$KSQL_DATAGEN_DELTA"
cp $INTERCEPTORS_CCLOUD_CONFIG $KSQL_DATAGEN_DELTA
echo "interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor" >> $KSQL_DATAGEN_DELTA

# Confluent Control Center runs locally, monitors Confluent Cloud, and uses Confluent Cloud cluster as the backstore
C3_DELTA=$DEST/control-center-ccloud.delta
echo "$C3_DELTA"
while read -r line
  do
  if [[ ! -z $line && ${line:0:1} != '#' ]]; then
    if [[ ${line:0:9} == 'bootstrap' ]]; then
      echo "$line" >> $C3_DELTA
    fi
    if [[ ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' ]]; then
      echo "confluent.controlcenter.streams.$line" >> $C3_DELTA
    fi
  fi
done < "$CCLOUD_CONFIG"

echo -e "\nKafka Clients:"

# Java
JAVA_CONFIG=$DEST/java.delta
echo "$JAVA_CONFIG"

cat <<EOF >> $JAVA_CONFIG
import java.util.Properties;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ConsumerConfig;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.streams.StreamsConfig;

Properties props = new Properties();

// Basic Confluent Cloud Connectivity
props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "$BOOTSTRAP_SERVERS");
props.put(StreamsConfig.REPLICATION_FACTOR_CONFIG, 3);
props.put(StreamsConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");

// Optimize Performance for Confluent Cloud
props.put(StreamsConfig.producerPrefix(ProducerConfig.RETRIES_CONFIG), 2147483647);
props.put("producer.confluent.batch.expiry.ms", 9223372036854775807);
props.put(StreamsConfig.producerPrefix(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG), 300000);
props.put(StreamsConfig.producerPrefix(ProducerConfig.MAX_BLOCK_MS_CONFIG), 9223372036854775807);

// Required for Streams Monitoring in Confluent Control Center
props.put(StreamsConfig.PRODUCER_PREFIX + ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor");
props.put(StreamsConfig.PRODUCER_PREFIX + ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, confluent.monitoring.interceptor.bootstrap.servers, "$BOOTSTRAP_SERVERS");
props.put(StreamsConfig.PRODUCER_PREFIX + ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + StreamsConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(StreamsConfig.PRODUCER_PREFIX + ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(StreamsConfig.PRODUCER_PREFIX + ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");
props.put(StreamsConfig.CONSUMER_PREFIX + ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG, "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor");
props.put(StreamsConfig.CONSUMER_PREFIX + ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, confluent.monitoring.interceptor.bootstrap.servers, "$BOOTSTRAP_SERVERS");
props.put(StreamsConfig.CONSUMER_PREFIX + ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + StreamsConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(StreamsConfig.CONSUMER_PREFIX + ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(StreamsConfig.CONSUMER_PREFIX + ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");

// ....
EOF


# .NET 
DOTNET_CONFIG=$DEST/dotnet.delta
echo "$DOTNET_CONFIG"

cat <<EOF >> $DOTNET_CONFIG
var producerConfig = new Dictionary<string, object>
{
    { "bootstrap.servers", "$BOOTSTRAP_SERVERS" },
    { "sasl.mechanisms", "PLAIN" },
    { "security.protocol", "SASL_SSL" },
    { "ssl.ca.location", "/usr/local/etc/openssl/cert.pem" }, // linux, osx
    // { "ssl.ca.location", "c:\\path\\to\\cacert.pem" },     // windows
    { "sasl.username", "$CLOUD_KEY" },
    { "sasl.password", "$CLOUD_SECRET" },
    { “plugin.library.paths”, “monitoring-interceptor”},
    // .....
};
var consumerConfig = new Dictionary<string, object>
{
    { "bootstrap.servers", "<confluent cloud bootstrap servers>" },
    { "sasl.mechanisms", "PLAIN" },
    { "security.protocol", "SASL_SSL" },
    { "ssl.ca.location", "/usr/local/etc/openssl/cert.pem" }, // linux, osx
    // { "ssl.ca.location", "c:\\path\\to\\cacert.pem" },     // windows
    { "sasl.username", "$CLOUD_KEY" },
    { "sasl.password", "$CLOUD_SECRET" },
    { “plugin.library.paths”, “monitoring-interceptor”},
    // .....
};
EOF
