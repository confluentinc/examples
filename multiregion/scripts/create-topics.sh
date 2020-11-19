#!/bin/bash

echo -e "\n==> Creating topic single-region"

docker-compose exec broker-west-1 kafka-topics  --create \
	--bootstrap-server broker-west-1:19091 \
	--topic single-region \
	--partitions 1 \
	--replica-placement /etc/kafka/demo/placement-single-region.json \
	--config min.insync.replicas=1

echo -e "\n==> Creating topic multi-region-sync"

docker-compose exec broker-west-1 kafka-topics  --create \
	--bootstrap-server broker-west-1:19091 \
	--topic multi-region-sync \
	--partitions 1 \
	--replica-placement /etc/kafka/demo/placement-multi-region-sync.json \
	--config min.insync.replicas=1

echo -e "\n==> Creating topic multi-region-async"

docker-compose exec broker-west-1 kafka-topics  --create \
	--bootstrap-server broker-west-1:19091 \
	--topic multi-region-async \
	--partitions 1 \
	--replica-placement /etc/kafka/demo/placement-multi-region-async.json \
	--config min.insync.replicas=1

echo -e "\n==> Creating topic multi-region-default"

# Note that the --replica-placement flag is not needed because we want to use
# the default placement constraints in this topic
docker-compose exec broker-west-1 kafka-topics  \
	--create \
	--bootstrap-server broker-west-1:19091 \
	--topic multi-region-default \
	--config min.insync.replicas=1

echo -e "\n==> Creating topic multi-region-async-op-under-min-isr"

docker-compose exec broker-west-1 kafka-topics  \
	--create \
	--bootstrap-server broker-west-1:19091 \
	--topic multi-region-async-op-under-min-isr \
	--partitions 1 \
	--replica-placement /etc/kafka/demo/placement-multi-region-async-op-under-min-isr.json \
	--config min.insync.replicas=2

echo -e "\n==> Creating topic multi-region-async-op-under-replicated"

docker-compose exec broker-west-1 kafka-topics  \
	--create \
	--bootstrap-server broker-west-1:19091 \
	--topic multi-region-async-op-under-replicated \
	--partitions 1 \
	--replica-placement /etc/kafka/demo/placement-multi-region-async-op-under-replicated.json \
	--config min.insync.replicas=1

echo -e "\n==> Creating topic multi-region-async-op-leader-is-observer"

docker-compose exec broker-west-1 kafka-topics  \
	--create \
	--bootstrap-server broker-west-1:19091 \
	--topic multi-region-async-op-leader-is-observer \
	--partitions 1 \
	--replica-placement /etc/kafka/demo/placement-multi-region-async-op-leader-is-observer.json \
	--config min.insync.replicas=1
