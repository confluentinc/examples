#!/bin/bash

echo -e "\n==> Create and describe topic multi-region-default with the topic configuration default"
read -p "Press any key to continue..."
echo
docker-compose exec broker-west-1 kafka-topics  \
	--create \
	--bootstrap-server broker-west-1:19091 \
	--topic multi-region-default

docker-compose exec broker-east-3 kafka-topics \
        --describe \
        --bootstrap-server broker-east-3:19093 \
	--topic multi-region-default

echo -e "\n==> Paritions with Invalid Replica Placement Constraints"
read -p "Press any key to continue..."
echo
docker-compose exec broker-east-3 kafka-topics \
	--bootstrap-server broker-east-3:19093 \
	--describe \
	--invalid-replica-placement-partitions

echo -e "\n==> Shutdown broker-west-1 and broker-west-2"
read -p "Press any key to continue..."
echo
docker-compose stop broker-west-1
docker-compose stop broker-west-2

echo -e "\n==> Wait for 10 seconds for update metadata to propagate\n"
sleep 10

echo -e "\n==> Partition should be unavailable"
read -p "Press any key to continue..."
echo
docker-compose exec broker-east-3 kafka-topics \
	--describe \
        --bootstrap-server broker-east-3:19093 \
	--topic multi-region-default

echo -e "\n==> Perform unclean leader election"
read -p "Press any key to continue..."
echo
docker-compose exec broker-east-3 kafka-leader-election \
	--bootstrap-server broker-east-3:19093 \
	--topic multi-region-default \
	--partition 0 \
	--election-type unclean

echo -e "\n==> Partition should be available"
read -p "Press any key to continue..."
echo
docker-compose exec broker-east-3 kafka-topics \
	--describe \
        --bootstrap-server broker-east-3:19093 \
	--topic multi-region-default

echo -e "\n==> Switching replica placement constraints"
read -p "Press any key to continue..."
echo
docker-compose exec broker-east-3 kafka-configs \
	--bootstrap-server broker-east-3:19093 \
	--alter --topic multi-region-default \
	--replica-placement /etc/kafka/demo/placement-multi-region-async-reverse.json

echo -e "\n==> Show the new replica placement configuration"
read -p "Press any key to continue..."
echo
docker-compose exec broker-east-3 kafka-topics \
	--bootstrap-server broker-east-3:19093 \
	--describe \
	--topic multi-region-default

echo -e "\n==> Running Confluent Rebalancer"
read -p "Press any key to continue..."
echo
docker-compose exec broker-east-3 confluent-rebalancer proposed-assignment \
	--metrics-bootstrap-server broker-east-3:19093 \
	--bootstrap-server broker-east-3:19093 \
	--replica-placement-only \
	--topics multi-region-default

docker-compose exec broker-east-3 confluent-rebalancer execute \
	--metrics-bootstrap-server broker-east-3:19093 \
	--bootstrap-server broker-east-3:19093 \
	--replica-placement-only \
	--topics multi-region-default \
	--force \
	--throttle 10000000

docker-compose exec broker-east-3 confluent-rebalancer finish \
	--bootstrap-server broker-east-3:19093

echo -e "\n==> Show the new replica placement configuration\n"
docker-compose exec broker-east-3 kafka-topics \
	--bootstrap-server broker-east-3:19093 \
	--describe \
	--topic multi-region-default

echo -e "\n==> Start broker-west-1 and broker-west-2"
read -p "Press any key to continue..."
echo
docker-compose start broker-west-1
docker-compose start broker-west-2

echo -e "\n==> Wait for 10 seconds for update metadata to propagate\n"
sleep 10

echo -e "\n==> Paritions with Invalid Replica Placement Constraints\n"
docker-compose exec broker-east-3 kafka-topics \
	--bootstrap-server broker-east-3:19093 \
	--describe \
	--invalid-replica-placement-partitions

echo -e "\n==> Show the new replica placement configuration\n"
docker-compose exec broker-east-3 kafka-topics \
	--bootstrap-server broker-east-3:19093 \
	--describe \
	--topic multi-region-default
