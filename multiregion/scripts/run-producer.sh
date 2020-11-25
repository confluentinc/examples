#!/bin/bash

echo -e "\n\n==> Produce: Single-region Replication (topic: single-region) \n"

docker-compose exec broker-west-1 kafka-producer-perf-test --topic single-region \
    --num-records 5000 \
    --record-size 5000 \
    --throughput -1 \
    --producer-props \
        acks=all \
        bootstrap.servers=broker-west-1:19091,broker-east-3:19093 \
        compression.type=none \
        batch.size=8196

echo -e "\n\n==> Produce: Multi-region Sync Replication (topic: multi-region-sync) \n"

docker-compose exec broker-west-1 kafka-producer-perf-test --topic multi-region-sync \
    --num-records 200 \
    --record-size 5000 \
    --throughput -1 \
    --producer-props \
        acks=all \
        bootstrap.servers=broker-west-1:19091,broker-east-3:19093 \
        compression.type=none \
        batch.size=8196

echo -e "\nSleeping 30 seconds"
sleep 30

echo -e "\n\n==> Produce: Multi-region Async Replication to Observers (topic: multi-region-async) \n"

docker-compose exec broker-west-1 kafka-producer-perf-test --topic multi-region-async \
    --num-records 5000 \
    --record-size 5000 \
    --throughput -1 \
    --producer-props \
        acks=all \
        bootstrap.servers=broker-west-1:19091,broker-east-3:19093 \
        compression.type=none \
        batch.size=8196

docker-compose exec broker-west-1 kafka-producer-perf-test --topic multi-region-async-op-under-min-isr \
    --num-records 5000 \
    --record-size 5000 \
    --throughput -1 \
    --producer-props \
        acks=all \
        bootstrap.servers=broker-west-1:19091,broker-east-3:19093 \
        compression.type=none \
        batch.size=8196

docker-compose exec broker-west-1 kafka-producer-perf-test --topic multi-region-async-op-under-replicated \
    --num-records 5000 \
    --record-size 5000 \
    --throughput -1 \
    --producer-props \
        acks=all \
        bootstrap.servers=broker-west-1:19091,broker-east-3:19093 \
        compression.type=none \
        batch.size=8196

docker-compose exec broker-west-1 kafka-producer-perf-test --topic multi-region-async-op-leader-is-observer \
    --num-records 5000 \
    --record-size 5000 \
    --throughput -1 \
    --producer-props \
        acks=all \
        bootstrap.servers=broker-west-1:19091,broker-east-3:19093 \
        compression.type=none \
        batch.size=8196