#!/bin/bash

docker-compose down
for v in $(docker volume ls -q --filter="dangling=true"); do
  docker volume rm "$v"
done

./stop-common.sh
