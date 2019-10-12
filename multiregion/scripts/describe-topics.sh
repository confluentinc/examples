#!/bin/bash

echo -e "\n==> Describe topic single-region\n"

docker-compose exec broker-east-3 kafka-topics --describe \
	--bootstrap-server broker-east-3:19093 --topic single-region

echo -e "\n==> Describe topic multi-region-async\n"

docker-compose exec broker-east-3 kafka-topics --describe \
	--bootstrap-server broker-east-3:19093 --topic multi-region-async

echo -e "\n==> Describe topic multi-region-sync\n"

docker-compose exec broker-east-3 kafka-topics --describe \
	--bootstrap-server broker-east-3:19093 --topic multi-region-sync
