#!/bin/bash

echo -e "\n\n==> Consume from east: Multi-region Async Replication reading from Leader in west (topic: multi-region-async) \n"

docker-compose exec broker-east-3 kafka-consumer-perf-test --topic multi-region-async \
    --messages 5000 \
    --threads 1 \
    --broker-list broker-west-1:19091,broker-east-3:19093 \
    --timeout 20000

echo -e "\n\n==> Consume from east: Multi-region Async Replication reading from Observer in east (topic: multi-region-async) \n"

docker-compose exec broker-east-3 kafka-consumer-perf-test --topic multi-region-async \
    --messages 5000 \
    --threads 1 \
    --broker-list broker-west-1:19091,broker-east-3:19093 \
    --timeout 20000 \
    --consumer.config /etc/kafka/demo/consumer-east.config

docker-compose exec broker-east-3 kafka-consumer-perf-test --topic multi-region-async-op-under-min-isr \
    --messages 5000 \
    --threads 1 \
    --broker-list broker-west-1:19091,broker-east-3:19093 \
    --timeout 20000 \
    --consumer.config /etc/kafka/demo/consumer-east.config

docker-compose exec broker-east-3 kafka-consumer-perf-test --topic multi-region-async-op-under-replicated \
    --messages 5000 \
    --threads 1 \
    --broker-list broker-west-1:19091,broker-east-3:19093 \
    --timeout 20000 \
    --consumer.config /etc/kafka/demo/consumer-east.config

docker-compose exec broker-east-3 kafka-consumer-perf-test --topic multi-region-async-op-leader-is-observer \
    --messages 5000 \
    --threads 1 \
    --broker-list broker-west-1:19091,broker-east-3:19093 \
    --timeout 20000 \
    --consumer.config /etc/kafka/demo/consumer-east.config