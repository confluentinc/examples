#!/bin/bash

for topic in single-region multi-region-sync multi-region-async multi-region-async-op-under-min-isr multi-region-async-op-under-replicated multi-region-async-op-leader-is-observer multi-region-default
do

  echo -e "\n==> Describe topic: $topic\n"

  docker-compose exec broker-east-3 kafka-topics --describe --bootstrap-server broker-east-3:19093 --topic $topic

done
