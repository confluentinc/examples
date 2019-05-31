#!/bin/bash

# Source library
. ../../../utils/helper.sh

check_ccloud || exit
check_jq || exit
check_ccloud_v1 || exit 1

./stop-docker.sh

../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.ccloud/config
source ./delta_configs/env.delta 

docker-compose up -d connect

ccloud topic create test2
docker-compose up -d ksql-datagen-avro
sleep 15
docker-compose exec connect bash -c 'kafka-avro-console-consumer --topic test2 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer.config /tmp/connect-ccloud.delta --property basic.auth.credentials.source=$CONNECT_VALUE_CONVERTER_BASIC_AUTH_CREDENTIALS_SOURCE --property schema.registry.basic.auth.user.info=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property schema.registry.url=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL --max-messages 5'
