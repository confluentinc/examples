#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../.env

${DIR}/stop.sh

# Confluent's ubi-based Docker images do not have 'tc' installed
echo
echo "Build custom cp-zookeeper and cp-server images with 'tc' installed"
for image in cp-zookeeper cp-server; do
  docker build --build-arg CP_VERSION=${CONFLUENT_DOCKER_TAG} --build-arg REPOSITORY=${REPOSITORY} --build-arg IMAGE=$image -t localbuild/${image}-tc:${CONFLUENT_DOCKER_TAG} -f Dockerfile .
done

docker-compose up -d

echo "Sleeping 20 seconds"
sleep 20

${DIR}/validate_connectivity.sh
if [[ $? != 0 ]]; then
  echo "Please troubleshoot"
  exit 1
fi

${DIR}/latency_docker.sh

${DIR}/validate_connectivity.sh
if [[ $? != 0 ]]; then
  echo "Please see the Troubleshooting section of the README"
  exit 1
fi

${DIR}/create-topics.sh

echo -e "\nSleeping 5 seconds"
sleep 5

${DIR}/describe-topics.sh

echo -e "\nSleeping 5 seconds"
sleep 5

${DIR}/run-producer.sh

echo "Sleeping 30 seconds"
sleep 30

${DIR}/run-consumer.sh

echo "Sleeping 5 seconds"
sleep 5

${DIR}/jmx_metrics.sh

echo -e "\nFail west region"
docker-compose stop broker-west-1 broker-west-2 zookeeper-west

echo "Sleeping 30 seconds"
sleep 30

${DIR}/describe-topics.sh

echo -e "\nFail over the observers in the topic multi-region-async to the east region, trigger leader election"

docker-compose exec broker-east-4 kafka-leader-election --bootstrap-server broker-east-4:19094 --election-type UNCLEAN --topic multi-region-async --partition 0

docker-compose exec broker-east-4 kafka-leader-election --bootstrap-server broker-east-4:19094 --election-type UNCLEAN --topic multi-region-default --partition 0

echo "Sleeping 30 seconds"
sleep 30

${DIR}/describe-topics.sh

echo "Sleeping 5 seconds"
sleep 5

${DIR}/permanent-fallback.sh

echo "Sleeping 30 seconds"
sleep 30

${DIR}/describe-topics.sh

echo -e "\nRestore west region"
docker-compose start broker-west-1 broker-west-2 zookeeper-west

echo "Sleeping 300 seconds until the leadership election restores the preferred replicas"
sleep 300

${DIR}/describe-topics.sh
