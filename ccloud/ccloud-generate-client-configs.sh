#!/bin/bash

############################################
# Process the Confluent Cloud configuration in $HOME/.ccloud/config
# to create delta configuration files in the destination directory
# with enabled interceptors for Streams Monitoring in Confluent Control Center
# for the following clients
# - Java (Streams)
#
# These are _delta_ configurations, not complete component configurations
############################################


# Confluent Cloud configuration
CCLOUD_CONFIG=$HOME/.ccloud/config

# Destination directory
if [[ ! -z "$1" ]]; then
  DEST=$1
else
  DEST="delta_client_configs"
fi
rm -fr $DEST
mkdir -p $DEST

if [[ ! -e $CCLOUD_CONFIG ]]; then
  echo "'ccloud' is not initialized. Run 'ccloud init' and try again"
  exit 1
fi

### Glean BOOTSTRAP_SERVERS and SASL_JAAS_CONFIG (key and password) from the Confluent Cloud configuration file
BOOTSTRAP_SERVERS=$( grep "^bootstrap.server" $CCLOUD_CONFIG | awk -F'=' '{print $2;}' )
SASL_JAAS_CONFIG=$( grep "^sasl.jaas.config" $CCLOUD_CONFIG | cut -d'=' -f2- )
echo "bootstrap.servers: $BOOTSTRAP_SERVERS"
echo "sasl.jaas.config: $SASL_JAAS_CONFIG"

### Java
JAVA_CONFIG=$DEST/java.config
echo -e "\nJava: $JAVA_CONFIG"

cat <<EOF >> $JAVA_CONFIG
import java.util.Properties;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.streams.StreamsConfig;

Properties props = new Properties();
props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "$BOOTSTRAP_SERVERS");
props.put(StreamsConfig.REPLICATION_FACTOR_CONFIG, 3);
props.put(StreamsConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(SaslConfigs.SASL_JAAS_CONFIG, "org.apache.kafka.common.security.plain.PlainLoginModule username=\"<confluent cloud access key>\" password=\"<confluent cloud secret>\";");

props.put(StreamsConfig.producerPrefix(ProducerConfig.RETRIES_CONFIG), 2147483647);
props.put("producer.confluent.batch.expiry.ms", 9223372036854775807);
props.put(StreamsConfig.producerPrefix(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG), 300000);
props.put(StreamsConfig.producerPrefix(ProducerConfig.MAX_BLOCK_MS_CONFIG), 9223372036854775807);
EOF

