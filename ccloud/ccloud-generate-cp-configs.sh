#!/bin/bash
#
# Copyright 2016 Confluent Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


###############################################################################
# Overview:
# This code reads the Confluent Cloud configuration in $HOME/.ccloud/config
# and writes delta configuration files into ./delta_configs for
# Confluent Platform components and clients connecting to Confluent Cloud.
#
# Add the delta configurations to the respective component configuration files
# or application code. Reminder: these are _delta_ configurations, not complete
# configurations. See https://docs.confluent.io/ for complete examples.
#
# Delta configurations include customized settings for:
# - bootstrap servers -> Confluent Cloud brokers
# - sasl.username -> key
# - sasl.password -> secret
# - interceptors for Streams Monitoring in Confluent Control Center
# - optimized performance to Confluent Cloud (varies based on client defaults)
#
# Confluent Platform Components: 
# - Confluent Schema Registry
# - KSQL Data Generator
# - KSQL server 
# - Confluent Replicator (executable)
# - Confluent Control Center
# - Kafka Connect
# - Kafka connector
#
# Kafka Clients:
# - Java (Producer/Consumer)
# - Java (Streams)
# - Python
# - .NET
# - Go
# - Node.js (https://github.com/Blizzard/node-rdkafka)
# - C++
#
# OS:
# - ENV file
###############################################################################

set -eu

################################################################################
# Confluent Cloud configuration
################################################################################
CCLOUD_CONFIG=$HOME/.ccloud/config
if [[ ! -f $CCLOUD_CONFIG ]]; then
  echo "'ccloud' is not initialized. Run 'ccloud init' and try again"
  exit 1
fi

PERM=600
if ls --version 2>/dev/null | grep -q 'coreutils' ; then
  # GNU binutils
  PERM=$(stat -c "%a" $HOME/.ccloud/config)
else
  # BSD
  PERM=$(stat -f "%OLp" $HOME/.ccloud/config)
fi
#echo "INFO: setting file permission to $PERM"

################################################################################
# Specify configuration file for Confluent Schema Registry
################################################################################
SR_CONFIG_FILE=$CCLOUD_CONFIG
if [[ $# -ne 0 ]] && [[ ! -z "$1" ]]; then
  SR_CONFIG_FILE=$1
fi
# Make destination
DEST="delta_configs"
mkdir -p $DEST

################################################################################
# Glean parameters from the Confluent Cloud configuration file
################################################################################
BOOTSTRAP_SERVERS=$( grep "^bootstrap.server" $CCLOUD_CONFIG | awk -F'=' '{print $2;}' )
BOOTSTRAP_SERVERS=${BOOTSTRAP_SERVERS/\\/}
BOOTSTRAP_SERVERS_SR_FORMAT="SASL_SSL://${BOOTSTRAP_SERVERS}"
BOOTSTRAP_SERVERS_SR_FORMAT=${BOOTSTRAP_SERVERS_SR_FORMAT//,/,SASL_SSL:\/\/}
BOOTSTRAP_SERVERS_SR_FORMAT=${BOOTSTRAP_SERVERS_SR_FORMAT/\\/}
SASL_JAAS_CONFIG=$( grep "^sasl.jaas.config" $CCLOUD_CONFIG | cut -d'=' -f2- )
CLOUD_KEY=$( echo $SASL_JAAS_CONFIG | awk '{print $3}' | awk -F'"' '$0=$2' )
CLOUD_SECRET=$( echo $SASL_JAAS_CONFIG | awk '{print $4}' | awk -F'"' '$0=$2' )
#echo "bootstrap.servers: $BOOTSTRAP_SERVERS"
#echo "sasl.jaas.config: $SASL_JAAS_CONFIG"
#echo "key: $CLOUD_KEY"
#echo "secret: $CLOUD_SECRET"

BASIC_AUTH_CREDENTIALS_SOURCE=$( grep "^basic.auth.credentials.source" $SR_CONFIG_FILE | awk -F'=' '{print $2;}' )
SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO=$( grep "^schema.registry.basic.auth.user.info" $SR_CONFIG_FILE | awk -F'=' '{print $2;}' )
SCHEMA_REGISTRY_URL=$( grep "^schema.registry.url" $SR_CONFIG_FILE | awk -F'=' '{print $2;}' )
#echo "basic.auth.credentials.source: $BASIC_AUTH_CREDENTIALS_SOURCE"
#echo "schema.registry.basic.auth.user.info: $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO"
#echo "schema.registry.url: $SCHEMA_REGISTRY_URL"


################################################################################
# Build configuration file with CCloud connection parameters and
# Confluent Monitoring Interceptors for Streams Monitoring in Confluent Control Center
################################################################################
INTERCEPTORS_CCLOUD_CONFIG=$DEST/interceptors-ccloud.config
rm -f $INTERCEPTORS_CCLOUD_CONFIG
echo "# Configuration derived from $CCLOUD_CONFIG" > $INTERCEPTORS_CCLOUD_CONFIG
while read -r line
do
  # Skip lines that are commented out
  if [[ ! -z $line && ${line:0:1} == '#' ]]; then
    continue
  fi
  # Skip lines that contain just whitespace
  if [[ -z "${line// }" ]]; then
    continue
  fi
  if [[ ${line:0:9} == 'bootstrap' ]]; then
    line=${line/\\/}
  fi
  echo $line >> $INTERCEPTORS_CCLOUD_CONFIG
done < "$CCLOUD_CONFIG"
echo -e "\n# Confluent Monitoring Interceptor specific configuration" >> $INTERCEPTORS_CCLOUD_CONFIG
while read -r line
do
  # Skip lines that are commented out
  if [[ ! -z $line && ${line:0:1} == '#' ]]; then
    continue
  fi
  # Skip lines that contain just whitespace
  if [[ -z "${line// }" ]]; then
    continue
  fi
  if [[ ${line:0:9} == 'bootstrap' ]]; then
    line=${line/\\/}
  fi
  if [[ ${line:0:4} == 'sasl' ||
        ${line:0:3} == 'ssl' ||
        ${line:0:8} == 'security' ||
        ${line:0:9} == 'bootstrap' ]]; then
    echo "confluent.monitoring.interceptor.$line" >> $INTERCEPTORS_CCLOUD_CONFIG
  fi
done < "$CCLOUD_CONFIG"
chmod $PERM $INTERCEPTORS_CCLOUD_CONFIG

echo -e "\nConfluent Platform Components:"

################################################################################
# Confluent Schema Registry instance (local) for Confluent Cloud
################################################################################
SR_CONFIG_DELTA=$DEST/schema-registry-ccloud.delta
echo "$SR_CONFIG_DELTA"
rm -f $SR_CONFIG_DELTA
while read -r line
do
  if [[ ! -z $line && ${line:0:1} != '#' ]]; then
    if [[ ${line:0:9} == 'bootstrap' && ! "$line" =~ "SASL_SSL:" ]]; then
      # Schema Registry requires security protocol, i.e. "SASL_SSL://", in kafkastore.bootstrap.servers
      # Workaround until this issue is resolved https://github.com/confluentinc/schema-registry/issues/790
      line=${line/=/=SASL_SSL:\/\/}
      line=${line//,/,SASL_SSL:\/\/}
      line=${line/\\/}
    fi
    if [[ ${line:0:29} != 'basic.auth.credentials.source' && ${line:0:15} != 'schema.registry' ]]; then
      echo "kafkastore.$line" >> $SR_CONFIG_DELTA
    fi
  fi
done < "$CCLOUD_CONFIG"
chmod $PERM $SR_CONFIG_DELTA

################################################################################
# Confluent Replicator (executable) for Confluent Cloud
################################################################################
REPLICATOR_PRODUCER_DELTA=$DEST/replicator-to-ccloud-producer.delta
echo "$REPLICATOR_PRODUCER_DELTA"
rm -f $REPLICATOR_PRODUCER_DELTA
cp $INTERCEPTORS_CCLOUD_CONFIG $REPLICATOR_PRODUCER_DELTA
echo -e "\n# Confluent Replicator (executable) specific configuration" >> $REPLICATOR_PRODUCER_DELTA
echo "interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor" >> $REPLICATOR_PRODUCER_DELTA
echo "request.timeout.ms=200000" >> $REPLICATOR_PRODUCER_DELTA
echo "retry.backoff.ms=500" >> $REPLICATOR_PRODUCER_DELTA
REPLICATOR_SASL_JAAS_CONFIG=$SASL_JAAS_CONFIG
REPLICATOR_SASL_JAAS_CONFIG=${REPLICATOR_SASL_JAAS_CONFIG//\\=/=}
REPLICATOR_SASL_JAAS_CONFIG=${REPLICATOR_SASL_JAAS_CONFIG//\"/\\\"}
chmod $PERM $REPLICATOR_PRODUCER_DELTA

################################################################################
# KSQL Server runs locally and connects to Confluent Cloud
################################################################################
KSQL_SERVER_DELTA=$DEST/ksql-server-ccloud.delta
echo "$KSQL_SERVER_DELTA"
cp $INTERCEPTORS_CCLOUD_CONFIG $KSQL_SERVER_DELTA
echo -e "\n# KSQL Server specific configuration" >> $KSQL_SERVER_DELTA
echo "producer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor" >> $KSQL_SERVER_DELTA
echo "consumer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor" >> $KSQL_SERVER_DELTA
echo "ksql.streams.producer.retries=2147483647" >> $KSQL_SERVER_DELTA
echo "ksql.streams.producer.confluent.batch.expiry.ms=9223372036854775807" >> $KSQL_SERVER_DELTA
echo "ksql.streams.producer.request.timeout.ms=300000" >> $KSQL_SERVER_DELTA
echo "ksql.streams.producer.max.block.ms=9223372036854775807" >> $KSQL_SERVER_DELTA
echo "ksql.streams.replication.factor=3" >> $KSQL_SERVER_DELTA
echo "ksql.sink.replicas=3" >> $KSQL_SERVER_DELTA
echo -e "\n# Confluent Schema Registry configuration for KSQL Server" >> $KSQL_SERVER_DELTA
while read -r line
do
  if [[ ${line:0:29} == 'basic.auth.credentials.source' ]]; then
    echo "ksql.schema.registry.$line" >> $KSQL_SERVER_DELTA
  elif [[ ${line:0:15} == 'schema.registry' ]]; then
    echo "ksql.$line" >> $KSQL_SERVER_DELTA
  fi
done < $SR_CONFIG_FILE
chmod $PERM $KSQL_SERVER_DELTA

################################################################################
# KSQL DataGen for Confluent Cloud
################################################################################
KSQL_DATAGEN_DELTA=$DEST/ksql-datagen.delta
echo "$KSQL_DATAGEN_DELTA"
rm -f $KSQL_DATAGEN_DELTA
cp $INTERCEPTORS_CCLOUD_CONFIG $KSQL_DATAGEN_DELTA
echo -e "\n# KSQL DataGen specific configuration" >> $KSQL_DATAGEN_DELTA
echo "interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor" >> $KSQL_DATAGEN_DELTA
echo -e "\n# Confluent Schema Registry configuration for KSQL DataGen" >> $KSQL_DATAGEN_DELTA
while read -r line
do
  if [[ ${line:0:29} == 'basic.auth.credentials.source' ]]; then
    echo "ksql.schema.registry.$line" >> $KSQL_DATAGEN_DELTA
  elif [[ ${line:0:15} == 'schema.registry' ]]; then
    echo "ksql.$line" >> $KSQL_DATAGEN_DELTA
  fi
done < $SR_CONFIG_FILE
chmod $PERM $KSQL_DATAGEN_DELTA

################################################################################
# Confluent Control Center runs locally, monitors Confluent Cloud, and uses Confluent Cloud cluster as the backstore
################################################################################
C3_DELTA=$DEST/control-center-ccloud.delta
echo "$C3_DELTA"
rm -f $C3_DELTA
echo -e "\n# Confluent Control Center specific configuration" >> $C3_DELTA
while read -r line
  do
  if [[ ! -z $line && ${line:0:1} != '#' ]]; then
    if [[ ${line:0:9} == 'bootstrap' ]]; then
      line=${line/\\/}
      echo "$line" >> $C3_DELTA
    fi
    if [[ ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' ]]; then
      echo "confluent.controlcenter.streams.$line" >> $C3_DELTA
    fi
  fi
done < "$CCLOUD_CONFIG"
echo -e "\n# Confluent Schema Registry configuration for Confluent Control Center" >> $C3_DELTA
while read -r line
do
  if [[ ${line:0:29} == 'basic.auth.credentials.source' ]]; then
    echo "confluent.controlcenter.schema.registry.$line" >> $C3_DELTA
  elif [[ ${line:0:15} == 'schema.registry' ]]; then
    echo "confluent.controlcenter.$line" >> $C3_DELTA
  fi
done < $SR_CONFIG_FILE
chmod $PERM $C3_DELTA

################################################################################
# Kafka Connect runs locally and connects to Confluent Cloud
################################################################################
CONNECT_DELTA=$DEST/connect-ccloud.delta
echo "$CONNECT_DELTA"
rm -f $CONNECT_DELTA
cat <<EOF > $CONNECT_DELTA
replication.factor=3
config.storage.replication.factor=3
offset.storage.replication.factor=3
status.storage.replication.factor=3
EOF
while read -r line
  do
  if [[ ! -z $line && ${line:0:1} != '#' ]]; then
    if [[ ${line:0:9} == 'bootstrap' ]]; then
      line=${line/\\/}
      echo "$line" >> $CONNECT_DELTA
    fi
    if [[ ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' ]]; then
      echo "$line" >> $CONNECT_DELTA
    fi
  fi
done < "$CCLOUD_CONFIG"
echo -e "\n# Connect producer and consumer specific configuration" >> $CONNECT_DELTA
while read -r line
  do
  if [[ ! -z $line && ${line:0:1} != '#' ]]; then
    if [[ ${line:0:9} == 'bootstrap' ]]; then
      line=${line/\\/}
    fi
    if [[ ${line:0:4} == 'sasl' || ${line:0:3} == 'ssl' || ${line:0:8} == 'security' ]]; then
      echo "producer.$line" >> $CONNECT_DELTA
      echo "producer.confluent.monitoring.interceptor.$line" >> $CONNECT_DELTA
      echo "consumer.$line" >> $CONNECT_DELTA
      echo "consumer.confluent.monitoring.interceptor.$line" >> $CONNECT_DELTA
    fi
  fi
done < "$CCLOUD_CONFIG"
cat <<EOF >> $CONNECT_DELTA

# Confluent Schema Registry for Kafka Connect
value.converter=io.confluent.connect.avro.AvroConverter
value.converter.basic.auth.credentials.source=$BASIC_AUTH_CREDENTIALS_SOURCE
value.converter.schema.registry.basic.auth.user.info=$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO
value.converter.schema.registry.url=$SCHEMA_REGISTRY_URL
EOF
chmod $PERM $CONNECT_DELTA

################################################################################
# Kafka connector
################################################################################
CONNECTOR_DELTA=$DEST/connector-ccloud.delta
echo "$CONNECTOR_DELTA"
rm -f $CONNECTOR_DELTA
cat <<EOF >> $CONNECTOR_DELTA
// Confluent Schema Registry for Kafka connectors
value.converter=io.confluent.connect.avro.AvroConverter
value.converter.basic.auth.credentials.source=$BASIC_AUTH_CREDENTIALS_SOURCE
value.converter.schema.registry.basic.auth.user.info=$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO
value.converter.schema.registry.url=$SCHEMA_REGISTRY_URL
EOF
chmod $PERM $CONNECTOR_DELTA


echo -e "\nKafka Clients:"

################################################################################
# Java (Producer/Consumer)
################################################################################
JAVA_PC_CONFIG=$DEST/java_producer_consumer.delta
echo "$JAVA_PC_CONFIG"
rm -f $JAVA_PC_CONFIG

cat <<EOF >> $JAVA_PC_CONFIG
import java.util.Properties;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ConsumerConfig;
import org.apache.kafka.common.config.SaslConfigs;

Properties props = new Properties();

// Basic Confluent Cloud Connectivity
props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "$BOOTSTRAP_SERVERS");
props.put(ProducerConfig.REPLICATION_FACTOR_CONFIG, 3);
props.put(ProducerConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");

// Confluent Schema Registry for Java
props.put("basic.auth.credentials.source", "$BASIC_AUTH_CREDENTIALS_SOURCE");
props.put("schema.registry.basic.auth.user.info", "$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO");
props.put("schema.registry.url", "$SCHEMA_REGISTRY_URL");

// Optimize Performance for Confluent Cloud
props.put(ProducerConfig.RETRIES_CONFIG, 2147483647);
props.put("producer.confluent.batch.expiry.ms", 9223372036854775807);
props.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, 300000);
props.put(ProducerConfig.MAX_BLOCK_MS_CONFIG, 9223372036854775807);

// Required for Streams Monitoring in Confluent Control Center
props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor");
props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, confluent.monitoring.interceptor.bootstrap.servers, "$BOOTSTRAP_SERVERS");
props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + ProducerConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");
props.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG, "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor");
props.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, confluent.monitoring.interceptor.bootstrap.servers, "$BOOTSTRAP_SERVERS");
props.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + ProducerConfig.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
props.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_MECHANISM, "PLAIN");
props.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG + SaslConfigs.SASL_JAAS_CONFIG, "$SASL_JAAS_CONFIG");

// .... additional configuration settings
EOF
chmod $PERM $JAVA_PC_CONFIG

################################################################################
# Java (Streams)
################################################################################
JAVA_STREAMS_CONFIG=$DEST/java_streams.delta
echo "$JAVA_STREAMS_CONFIG"
rm -f $JAVA_STREAMS_CONFIG

cat <<EOF >> $JAVA_STREAMS_CONFIG
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

// Confluent Schema Registry for Java
props.put("basic.auth.credentials.source", "$BASIC_AUTH_CREDENTIALS_SOURCE");
props.put("schema.registry.basic.auth.user.info", "$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO");
props.put("schema.registry.url", "$SCHEMA_REGISTRY_URL");

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

// .... additional configuration settings
EOF
chmod $PERM $JAVA_STREAMS_CONFIG

################################################################################
# Python
################################################################################
PYTHON_CONFIG=$DEST/python.delta
echo "$PYTHON_CONFIG"
rm -f $PYTHON_CONFIG

cat <<EOF >> $PYTHON_CONFIG
from confluent_kafka import Producer, Consumer, KafkaError

producer = Producer({
           'bootstrap.servers': '$BOOTSTRAP_SERVERS',
           'broker.version.fallback': '0.10.0.0',
           'api.version.fallback.ms': 0,
           'sasl.mechanisms': 'PLAIN',
           'security.protocol': 'SASL_SSL',
           'sasl.username': '$CLOUD_KEY',
           'sasl.password': '$CLOUD_SECRET',
           // 'ssl.ca.location': '/usr/local/etc/openssl/cert.pem', // varies by distro
           'plugin.library.paths': 'monitoring-interceptor',
           // .... additional configuration settings
})

consumer = Consumer({
           'bootstrap.servers': '$BOOTSTRAP_SERVERS',
           'broker.version.fallback': '0.10.0.0',
           'api.version.fallback.ms': 0,
           'sasl.mechanisms': 'PLAIN',
           'security.protocol': 'SASL_SSL',
           'sasl.username': '$CLOUD_KEY',
           'sasl.password': '$CLOUD_SECRET',
           // 'ssl.ca.location': '/usr/local/etc/openssl/cert.pem', // varies by distro
           'plugin.library.paths': 'monitoring-interceptor',
           // .... additional configuration settings
})
EOF
chmod $PERM $PYTHON_CONFIG

################################################################################
# .NET 
################################################################################
DOTNET_CONFIG=$DEST/dotnet.delta
echo "$DOTNET_CONFIG"
rm -f $DOTNET_CONFIG

cat <<EOF >> $DOTNET_CONFIG
using Confluent.Kafka;

var producerConfig = new Dictionary<string, object>
{
    { "bootstrap.servers", "$BOOTSTRAP_SERVERS" },
    { "broker.version.fallback", "0.10.0.0" },
    { "api.version.fallback.ms", 0 },
    { "sasl.mechanisms", "PLAIN" },
    { "security.protocol", "SASL_SSL" },
    { "sasl.username", "$CLOUD_KEY" },
    { "sasl.password", "$CLOUD_SECRET" },
    // { "ssl.ca.location", "/usr/local/etc/openssl/cert.pem" }, // varies by distro
    { “plugin.library.paths”, “monitoring-interceptor”},
    // .... additional configuration settings
};

var consumerConfig = new Dictionary<string, object>
{
    { "bootstrap.servers", "$BOOTSTRAP_SERVERS" },
    { "broker.version.fallback", "0.10.0.0" },
    { "api.version.fallback.ms", 0 },
    { "sasl.mechanisms", "PLAIN" },
    { "security.protocol", "SASL_SSL" },
    { "sasl.username", "$CLOUD_KEY" },
    { "sasl.password", "$CLOUD_SECRET" },
    // { "ssl.ca.location", "/usr/local/etc/openssl/cert.pem" }, // varies by distro
    { “plugin.library.paths”, “monitoring-interceptor”},
    // .... additional configuration settings
};
EOF
chmod $PERM $DOTNET_CONFIG

################################################################################
# Go
################################################################################
GO_CONFIG=$DEST/go.delta
echo "$GO_CONFIG"
rm -f $GO_CONFIG

cat <<EOF >> $GO_CONFIG
import (
	"github.com/confluentinc/confluent-kafka-go/kafka"
)

producer, err := kafka.NewProducer(&kafka.ConfigMap{
	         "bootstrap.servers": "$BOOTSTRAP_SERVERS",
	         "broker.version.fallback": "0.10.0.0",
	         "api.version.fallback.ms": 0,
	         "sasl.mechanisms": "PLAIN",
	         "security.protocol": "SASL_SSL",
	         "sasl.username": "$CLOUD_KEY",
	         "sasl.password": "$CLOUD_SECRET",
                 // "ssl.ca.location": "/usr/local/etc/openssl/cert.pem", // varies by distro
                 "plugin.library.paths": "monitoring-interceptor",
                 // .... additional configuration settings
                 })

consumer, err := kafka.NewConsumer(&kafka.ConfigMap{
		 "bootstrap.servers": "$BOOTSTRAP_SERVERS",
		 "broker.version.fallback": "0.10.0.0",
		 "api.version.fallback.ms": 0,
		 "sasl.mechanisms": "PLAIN",
		 "security.protocol": "SASL_SSL",
		 "sasl.username": "$CLOUD_KEY",
		 "sasl.password": "$CLOUD_SECRET",
                 // "ssl.ca.location": "/usr/local/etc/openssl/cert.pem", // varies by distro
		 "session.timeout.ms": 6000,
                 "plugin.library.paths": "monitoring-interceptor",
                 // .... additional configuration settings
                 })
EOF
chmod $PERM $GO_CONFIG

################################################################################
# Node.js
################################################################################
NODE_CONFIG=$DEST/node.delta
echo "$NODE_CONFIG"
rm -f $NODE_CONFIG

cat <<EOF >> $NODE_CONFIG
var Kafka = require('node-rdkafka');

var producer = new Kafka.Producer({
    'metadata.broker.list': '$BOOTSTRAP_SERVERS',
    'sasl.mechanisms': 'PLAIN',
    'security.protocol': 'SASL_SSL',
    'sasl.username': '$CLOUD_KEY',
    'sasl.password': '$CLOUD_SECRET',
     // 'ssl.ca.location': '/usr/local/etc/openssl/cert.pem', // varies by distro
    'plugin.library.paths': 'monitoring-interceptor',
    // .... additional configuration settings
  });

var consumer = Kafka.KafkaConsumer.createReadStream({
    'metadata.broker.list': '$BOOTSTRAP_SERVERS',
    'sasl.mechanisms': 'PLAIN',
    'security.protocol': 'SASL_SSL',
    'sasl.username': '$CLOUD_KEY',
    'sasl.password': '$CLOUD_SECRET',
     // 'ssl.ca.location': '/usr/local/etc/openssl/cert.pem', // varies by distro
    'plugin.library.paths': 'monitoring-interceptor',
    // .... additional configuration settings
  }, {}, {
    topics: '<topic name>',
    waitInterval: 0,
    objectMode: false
});
EOF
chmod $PERM $NODE_CONFIG

################################################################################
# C++
################################################################################
CPP_CONFIG=$DEST/cpp.delta
echo "$CPP_CONFIG"
rm -f $CPP_CONFIG

cat <<EOF >> $CPP_CONFIG
#include <librdkafka/rdkafkacpp.h>

RdKafka::Conf *producerConfig = RdKafka::Conf::create(RdKafka::Conf::CONF_GLOBAL);
if (producerConfig->set("metadata.broker.list", "$BOOTSTRAP_SERVERS", errstr) != RdKafka::Conf::CONF_OK ||
    producerConfig->set("sasl.mechanisms", "PLAIN", errstr) != RdKafka::Conf::CONF_OK ||
    producerConfig->set("security.protocol", "SASL_SSL", errstr) != RdKafka::Conf::CONF_OK ||
    producerConfig->set("sasl.username", "$CLOUD_KEY", errstr) != RdKafka::Conf::CONF_OK ||
    producerConfig->set("sasl.password", "$CLOUD_SECRET", errstr) != RdKafka::Conf::CONF_OK ||
    // producerConfig->set("ssl.ca.location", "/usr/local/etc/openssl/cert.pem", errstr) != RdKafka::Conf::CONF_OK || // varies by distro
    producerConfig->set("plugin.library.paths", "monitoring-interceptor", errstr) != RdKafka::Conf::CONF_OK ||
    // .... additional configuration settings
   ) {
        std::cerr << "Configuration failed: " << errstr << std::endl;
        exit(1);
}
RdKafka::Producer *producer = RdKafka::Producer::create(producerConfig, errstr);

RdKafka::Conf *consumerConfig = RdKafka::Conf::create(RdKafka::Conf::CONF_GLOBAL);
if (consumerConfig->set("metadata.broker.list", "$BOOTSTRAP_SERVERS", errstr) != RdKafka::Conf::CONF_OK ||
    consumerConfig->set("sasl.mechanisms", "PLAIN", errstr) != RdKafka::Conf::CONF_OK ||
    consumerConfig->set("security.protocol", "SASL_SSL", errstr) != RdKafka::Conf::CONF_OK ||
    consumerConfig->set("sasl.username", "$CLOUD_KEY", errstr) != RdKafka::Conf::CONF_OK ||
    consumerConfig->set("sasl.password", "$CLOUD_SECRET", errstr) != RdKafka::Conf::CONF_OK ||
    // consumerConfig->set("ssl.ca.location", "/usr/local/etc/openssl/cert.pem", errstr) != RdKafka::Conf::CONF_OK || // varies by distro
    consumerConfig->set("plugin.library.paths", "monitoring-interceptor", errstr) != RdKafka::Conf::CONF_OK ||
    // .... additional configuration settings
   ) {
        std::cerr << "Configuration failed: " << errstr << std::endl;
        exit(1);
}
RdKafka::Consumer *consumer = RdKafka::Consumer::create(consumerConfig, errstr);
EOF
chmod $PERM $CPP_CONFIG

################################################################################
# ENV
################################################################################
ENV_CONFIG=$DEST/env.delta
echo "$ENV_CONFIG"
rm -f $ENV_CONFIG

cat <<EOF >> $ENV_CONFIG
export BOOTSTRAP_SERVERS='$BOOTSTRAP_SERVERS'
export SASL_JAAS_CONFIG='$SASL_JAAS_CONFIG'
export BOOTSTRAP_SERVERS_SR_FORMAT='$BOOTSTRAP_SERVERS_SR_FORMAT'
export REPLICATOR_SASL_JAAS_CONFIG='$REPLICATOR_SASL_JAAS_CONFIG'
export BASIC_AUTH_CREDENTIALS_SOURCE=$BASIC_AUTH_CREDENTIALS_SOURCE
export SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO=$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO
export SCHEMA_REGISTRY_URL=$SCHEMA_REGISTRY_URL
EOF
chmod $PERM $ENV_CONFIG
