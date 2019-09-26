#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

${DIR}/stop.sh

echo "Sleeping 2 seconds"
sleep 2

docker-compose up -d

echo "Sleeping 30 seconds"
sleep 30

${DIR}/create-topics.sh

echo "Sleeping 10 seconds"
sleep 10

${DIR}/describe-topics.sh

echo "Sleeping 2 seconds"
sleep 2

${DIR}/latency_docker.sh

echo "Sleeping 30 seconds"
sleep 30

# Describe topics again
${DIR}/describe-topics.sh

${DIR}/start-producer.sh

echo "Sleeping 30 seconds"
sleep 30

${DIR}/start-consumer.sh
