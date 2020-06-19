#!/bin/bash

BOOTSTRAP_SERVER=${BOOTSTRAP_SERVER:-"broker:9092"}
PARTITIONS=${PARTITIONS:-1}
REPLICATION_FACTOR=${REPLICATION_FACTOR:-1}

kafka-topics --create --bootstrap-server $BOOTSTRAP_SERVER --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR --topic orders $ADDITIONAL_ARGS
kafka-topics --create --bootstrap-server $BOOTSTRAP_SERVER --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR --topic order-validations $ADDITIONAL_ARGS
kafka-topics --create --bootstrap-server $BOOTSTRAP_SERVER --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR --topic warehouse-inventory $ADDITIONAL_ARGS
kafka-topics --create --bootstrap-server $BOOTSTRAP_SERVER --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR --topic customers $ADDITIONAL_ARGS 
kafka-topics --create --bootstrap-server $BOOTSTRAP_SERVER --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR --topic payments $ADDITIONAL_ARGS
kafka-topics --create --bootstrap-server $BOOTSTRAP_SERVER --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR --topic platinum $ADDITIONAL_ARGS
kafka-topics --create --bootstrap-server $BOOTSTRAP_SERVER --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR --topic gold $ADDITIONAL_ARGS
kafka-topics --create --bootstrap-server $BOOTSTRAP_SERVER --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR --topic silver $ADDITIONAL_ARGS
kafka-topics --create --bootstrap-server $BOOTSTRAP_SERVER --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR --topic bronze $ADDITIONAL_ARGS
