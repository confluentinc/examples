#!/bin/bash

# Source library
source ../../../utils/helper.sh
source ../../../utils/ccloud_library.sh

check_jq || exit

CONFIG_FILE=$HOME/.confluent/java.config
ccloud::validate_ccloud_config $CONFIG_FILE || exit

./stop-docker.sh

ccloud::generate_configs $CONFIG_FILE
source ./delta_configs/env.delta 

docker-compose up -d
echo "Sleeping 90 seconds"
sleep 90
./delete-topics.sh

docker-compose exec connect bash -c 'kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" /tmp/ak-tools-ccloud.delta | tail -1` --command-config /tmp/ak-tools-ccloud.delta --topic test1 --create --replication-factor 3 --partitions 6'
source ./submit_datagen_orders_config.sh
#docker-compose exec connect bash -c 'kafka-console-consumer --topic test1 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer.config /tmp/ak-tools-ccloud.delta --max-messages 5'
docker-compose exec connect bash -c 'kafka-console-consumer --topic test1 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer-property sasl.mechanism=PLAIN --consumer-property security.protocol=SASL_SSL --consumer-property sasl.jaas.config="$SASL_JAAS_CONFIG_PROPERTY_FORMAT" --max-messages 5'
