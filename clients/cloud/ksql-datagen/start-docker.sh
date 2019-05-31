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

ccloud topic create test1
docker-compose up -d ksql-datagen
sleep 15
docker-compose exec connect bash -c 'kafka-console-consumer --topic test1 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer.config /tmp/connect-ccloud.delta --max-messages 5'
