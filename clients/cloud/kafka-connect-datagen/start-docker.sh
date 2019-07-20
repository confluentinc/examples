#!/bin/bash

# Source library
. ../../../utils/helper.sh

check_jq || exit

CONFIG_FILE=~/.ccloud/config
check_ccloud_config $CONFIG_FILE || exit

./stop-docker.sh

../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.ccloud/config
source ./delta_configs/env.delta 

docker-compose up -d --build
sleep 90

docker-compose exec connect bash -c 'kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" /tmp/ak-tools-ccloud.delta | tail -1` --command-config /tmp/ak-tools-ccloud.delta --topic test1 --create --replication-factor 3 --partitions 6'
. ./submit_datagen_orders_config.sh
#docker-compose exec connect bash -c 'kafka-console-consumer --topic test1 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer.config /tmp/ak-tools-ccloud.delta --max-messages 5'
docker-compose exec connect bash -c 'kafka-console-consumer --topic test1 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer-property ssl.endpoint.identification.algorithm=https --consumer-property sasl.mechanism=PLAIN --consumer-property security.protocol=SASL_SSL --consumer-property sasl.jaas.config="$SASL_JAAS_CONFIG_PROPERTY_FORMAT" --max-messages 5'
