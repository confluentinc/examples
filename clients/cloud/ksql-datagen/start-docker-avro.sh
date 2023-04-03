#!/bin/bash

# Source library
source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh

CONFIG_FILE="${CONFIG_FILE:-$HOME/.confluent/java.config}"
ccloud::validate_ccloud_config $CONFIG_FILE || exit

./stop-docker.sh

ccloud::generate_configs $CONFIG_FILE
source ./delta_configs/env.delta 

docker-compose up -d connect
sleep 5
./delete-topics.sh

docker-compose exec connect bash -c 'kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" /tmp/ak-tools-ccloud.delta | tail -1` --command-config /tmp/ak-tools-ccloud.delta --topic test2 --create --replication-factor 3 --partitions 6'
docker-compose up -d ksql-datagen-avro
echo "Sleeping 15 seconds"
sleep 15

#docker-compose exec connect bash -c 'kafka-avro-console-consumer --topic test2 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer.config /tmp/ak-tools-ccloud.delta --property basic.auth.credentials.source=$CONNECT_VALUE_CONVERTER_BASIC_AUTH_CREDENTIALS_SOURCE --property schema.registry.basic.auth.user.info=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property schema.registry.url=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL --max-messages 5'
docker-compose exec connect bash -c 'kafka-avro-console-consumer --topic test2 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer-property sasl.mechanism=PLAIN --consumer-property security.protocol=SASL_SSL --consumer-property sasl.jaas.config="$SASL_JAAS_CONFIG_PROPERTY_FORMAT" --property basic.auth.credentials.source=$CONNECT_VALUE_CONVERTER_BASIC_AUTH_CREDENTIALS_SOURCE --property schema.registry.basic.auth.user.info=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property schema.registry.url=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL --max-messages 5'
