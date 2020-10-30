#!/bin/bash
  
#docker container stop pumba-medium-latency-central
#docker container stop pumba-high-latency-west-east
#docker container stop pumba-loss-west-east
#docker container stop pumba-loss-east-west
#docker container ls -a --filter "ancestor=gaiadocker/iproute2" | grep -v CONTAINER | awk '{print $1;}' | xargs docker container rm --filter "ancestor=gaiadocker/iproute2"

docker-compose down -v --remove-orphans
