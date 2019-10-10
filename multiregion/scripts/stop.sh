#!/bin/bash
  
docker container stop pumba-medium-latency-central
docker container stop pumba-high-latency-west-east
docker container stop pumba-loss-west-east
docker container stop pumba-loss-east-west

docker-compose down -v --remove-orphans

sleep 1
