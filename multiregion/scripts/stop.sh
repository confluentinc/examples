#!/bin/bash
  
docker container stop pumba-zk-central
docker container stop pumba-delay
docker container stop pumba-rate-limit

docker-compose down
