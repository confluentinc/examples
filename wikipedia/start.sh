#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 5.1 || exit 
check_running_elasticsearch 5.6.5 || exit 1
check_running_kibana || exit 1

./stop.sh

# Add custom connector and SMT
mkdir -p $CONFLUENT_HOME/share/java/kafka-connect-irc
cp -nR ./kafka-connect-irc/* $CONFLUENT_HOME/share/java/kafka-connect-irc/.
cp -nR WikiEditTransformation-3.3.0.jar $CONFLUENT_HOME/share/java/.
confluent start

kafka-topics --zookeeper localhost:2181 --topic wikipedia.parsed --create --replication-factor 1 --partitions 2
kafka-topics --zookeeper localhost:2181 --topic wikipedia.parsed.replica --create --replication-factor 1 --partitions 4
kafka-topics --zookeeper localhost:2181 --topic wikipedia.failed --create --replication-factor 1 --partitions 2
kafka-topics --zookeeper localhost:2181 --topic WIKIPEDIABOT --create --replication-factor 1 --partitions 2
kafka-topics --zookeeper localhost:2181 --topic WIKIPEDIANOBOT --create --replication-factor 1 --partitions 2
kafka-topics --zookeeper localhost:2181 --topic EN_WIKIPEDIA_GT_1 --create --replication-factor 1 --partitions 2
kafka-topics --zookeeper localhost:2181 --topic EN_WIKIPEDIA_GT_1_COUNTS --create --replication-factor 1 --partitions 2

if is_ce; then confluent config wikipedia-irc -d ./connector_irc.config; else confluent config wikipedia-irc -d ./connector_irc_oss.config; fi
sleep 10

#kafka-avro-console-consumer --bootstrap-server localhost:9092 --topic wikipedia.parsed --property schema.registry.url=http://localhost:8081 --max-messages 5

ksql http://localhost:8088 <<EOF
run script 'ksql.commands';
exit ;
EOF
sleep 10

if is_ce; then confluent config replicate-topic -d ./connector_replicator.config; fi
if is_ce; then confluent config elasticsearch -d ./connector_elasticsearch.config; else confluent config elasticsearch -d ./connector_elasticsearch_oss.config; fi

./dashboard/set_elasticsearch_mapping_bot.sh
./dashboard/set_elasticsearch_mapping_count.sh
./dashboard/configure_kibana_dashboard.sh
