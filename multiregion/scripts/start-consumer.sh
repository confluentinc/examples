#!/bin/bash

echo -e "\n\n==> Consume from east: Multi-region Async Replication from Leader in west (topic: multi-region-async) \n"

docker-compose exec broker-east-3 kafka-consumer-perf-test --topic multi-region-async \
    --messages 5000 \
    --threads 1 \
    --broker-list broker-west-1:19091,broker-east-3:19093

echo -e "\n\n==> Consume from east: Multi-region Async Replication from Follower in east (topic: multi-region-async) \n"

docker-compose exec broker-east-3 kafka-consumer-perf-test --topic multi-region-async \
    --messages 5000 \
    --threads 1 \
    --broker-list broker-west-1:19091,broker-east-3:19093 \
    --consumer.config /etc/kafka/demo/consumer-east.config
