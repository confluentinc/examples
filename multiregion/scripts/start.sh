#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../.env

${DIR}/stop.sh

${DIR}/build_docker_images.sh

export RUN_JMX=${RUN_JMX:-true}

echo "Bring up docker-compose"
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

echo -e "\n=========== Steady state ===========\n"

${DIR}/describe-topics.sh

echo -e "\nSleeping 5 seconds"
sleep 5

${DIR}/run-producer.sh

echo "Sleeping 30 seconds"
sleep 30

${DIR}/run-consumer.sh

echo "Sleeping 5 seconds"
sleep 5

if [[ $RUN_JMX == "true" ]]; then ${DIR}/jmx_metrics.sh; fi

echo -e "\n=========== Degrade west region ===========\n"

docker-compose stop broker-west-1

echo "Sleeping 30 seconds"
sleep 30

${DIR}/describe-topics.sh

echo "Sleeping 30 seconds"
sleep 30

if [[ $RUN_JMX == "true" ]]; then ${DIR}/jmx_metrics.sh; fi

echo -e "\n=========== Fail west region ===========\n"

docker-compose stop broker-west-2 zookeeper-west

echo "Sleeping 30 seconds"
sleep 30

${DIR}/describe-topics.sh

if [[ $RUN_JMX == "true" ]]; then ${DIR}/jmx_metrics.sh; fi

echo -e "\nFail over the observers in the topic multi-region-async to the east region, trigger leader election"

docker-compose exec broker-east-4 kafka-leader-election --bootstrap-server broker-east-4:19094 --election-type UNCLEAN --topic multi-region-async --partition 0

docker-compose exec broker-east-4 kafka-leader-election --bootstrap-server broker-east-4:19094 --election-type UNCLEAN --topic multi-region-default --partition 0

echo "Sleeping 30 seconds"
sleep 30

${DIR}/describe-topics.sh

echo "Sleeping 5 seconds"
sleep 5

if [[ $RUN_JMX == "true" ]]; then ${DIR}/jmx_metrics.sh; fi

${DIR}/permanent-failover.sh

echo "Sleeping 30 seconds"
sleep 30

${DIR}/describe-topics.sh

if [[ $RUN_JMX == "true" ]]; then ${DIR}/jmx_metrics.sh; fi

echo -e "\n=========== Restore west region  ===========\n"
docker-compose start broker-west-1 broker-west-2 zookeeper-west

echo "Sleeping 300 seconds until the leadership election restores the preferred replicas"
sleep 300

${DIR}/describe-topics.sh

if [[ $RUN_JMX == "true" ]]; then ${DIR}/jmx_metrics.sh; fi
