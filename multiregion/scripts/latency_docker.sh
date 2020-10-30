#!/bin/bash

##########################################################################
# This code injects latency between the regions and packet loss to simulate the WAN link
# by configuring 'tc' commands directly on ZooKeeper and broker containers
#
# Running Pumba is an alternate method but is commented out because:
# - Pumba can't run 'tc' on the Confluent containers because Docker containers run as 'appuser', not 'root'
# - Pumba could run with '--tc-image gaiadocker/iproute2' flag (does not require 'tc' on Docker containers)
#   but that works only on the first run and fails on subsequent runs, requiring a Docker restart in between runs
# - Because the outcomes are inconsistent, code uses 'tc' instead of Pumba
##########################################################################
  
export DOCKER_NETWORK=multiregion_n1
export ZOOKEEPER_WEST_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' zookeeper-west)
export ZOOKEEPER_EAST_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' zookeeper-east)
export KAFKA_WEST_1_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-west-1)
export KAFKA_WEST_2_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-west-2)
export KAFKA_EAST_3_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-east-3)
export KAFKA_EAST_4_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-east-4)
export SUBNET=$(docker inspect multiregion_n1 -f '{{(index .IPAM.Config 0).Subnet}}')

echo -e "\n==> Configuring central as a medium latency link (50ms)"
#docker run --rm -d \
#        --network=${DOCKER_NETWORK} \
#        --name pumba-medium-latency-central \
#        -v /var/run/docker.sock:/var/run/docker.sock \
#        -e SUBNET=${SUBNET} \
#        gaiaadm/pumba:0.7.6 -l debug netem --duration 24000h \
#                --tc-image gaiadocker/iproute2 \
#                --target $SUBNET \
#                delay --time 50 zookeeper-central --jitter 10 &
docker-compose exec -u0 zookeeper-central tc qdisc add dev eth0 root handle 1: prio > /dev/null
docker-compose exec -u0 zookeeper-central tc qdisc add dev eth0 parent 1:1 handle 10: sfq > /dev/null
docker-compose exec -u0 zookeeper-central tc qdisc add dev eth0 parent 1:2 handle 20: sfq > /dev/null
docker-compose exec -u0 zookeeper-central tc qdisc add dev eth0 parent 1:3 handle 30: netem delay 50ms 10ms 20.00 > /dev/null
docker-compose exec -u0 zookeeper-central tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $SUBNET flowid 1:3 > /dev/null

echo -e "\n==> Configuring west-east as a high latency link (100ms)"
#docker run --rm -d \
#        --network=${DOCKER_NETWORK} \
#        --name pumba-high-latency-west-east \
#        -v /var/run/docker.sock:/var/run/docker.sock \
#        -e ZOOKEEPER_EAST_IP=${ZOOKEEPER_EAST_IP} \
#        -e KAFKA_EAST_3_IP=${KAFKA_EAST_3_IP} \
#        -e KAFKA_EAST_4_IP=${KAFKA_EAST_4_IP} \
#        gaiaadm/pumba:0.7.6 -l debug netem --duration 24000h \
#                --tc-image gaiadocker/iproute2 \
#                --target ${ZOOKEEPER_EAST_IP} \
#                --target ${KAFKA_EAST_3_IP} \
#                --target ${KAFKA_EAST_4_IP} \
#                delay --time 100 zookeeper-west broker-west-1 broker-west-2 --jitter 20 &
docker-compose exec -u0 zookeeper-west tc qdisc add dev eth0 root handle 1: prio > /dev/null
docker-compose exec -u0 broker-west-2 tc qdisc add dev eth0 root handle 1: prio > /dev/null
docker-compose exec -u0 broker-west-1 tc qdisc add dev eth0 root handle 1: prio > /dev/null
docker-compose exec -u0 zookeeper-west tc qdisc add dev eth0 parent 1:1 handle 10: sfq > /dev/null
docker-compose exec -u0 broker-west-2 tc qdisc add dev eth0 parent 1:1 handle 10: sfq > /dev/null
docker-compose exec -u0 broker-west-1 tc qdisc add dev eth0 parent 1:1 handle 10: sfq > /dev/null
docker-compose exec -u0 zookeeper-west tc qdisc add dev eth0 parent 1:2 handle 20: sfq > /dev/null
docker-compose exec -u0 broker-west-2 tc qdisc add dev eth0 parent 1:2 handle 20: sfq > /dev/null
docker-compose exec -u0 broker-west-1 tc qdisc add dev eth0 parent 1:2 handle 20: sfq > /dev/null
docker-compose exec -u0 zookeeper-west tc qdisc add dev eth0 parent 1:3 handle 30: netem delay 100ms 20ms 20.00 > /dev/null
docker-compose exec -u0 broker-west-2 tc qdisc add dev eth0 parent 1:3 handle 30: netem delay 100ms 20ms 20.00 > /dev/null
docker-compose exec -u0 broker-west-1 tc qdisc add dev eth0 parent 1:3 handle 30: netem delay 100ms 20ms 20.00 > /dev/null
docker-compose exec -u0 broker-west-1 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $ZOOKEEPER_EAST_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-west-2 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $ZOOKEEPER_EAST_IP flowid 1:3 > /dev/null
docker-compose exec -u0 zookeeper-west tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $ZOOKEEPER_EAST_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-west-1 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_3_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-west-2 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_3_IP flowid 1:3 > /dev/null
docker-compose exec -u0 zookeeper-west tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_3_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-west-2 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_4_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-west-1 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_4_IP flowid 1:3 > /dev/null
docker-compose exec -u0 zookeeper-west tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_4_IP flowid 1:3 > /dev/null

echo -e "\n==> Configuring west-east with 1% packet loss"
#docker run --rm -d \
#        --network=${DOCKER_NETWORK} \
#        --name pumba-loss-west-east \
#        -v /var/run/docker.sock:/var/run/docker.sock \
#        -e ZOOKEEPER_EAST_IP=${ZOOKEEPER_EAST_IP} \
#        -e KAFKA_EAST_3_IP=${KAFKA_EAST_3_IP} \
#        -e KAFKA_EAST_4_IP=${KAFKA_EAST_4_IP} \
#        gaiaadm/pumba:0.7.6 -l debug netem --duration 24000h \
#                --tc-image gaiadocker/iproute2 \
#                --target ${ZOOKEEPER_EAST_IP} \
#                --target ${KAFKA_EAST_3_IP} \
#                --target ${KAFKA_EAST_4_IP} \
#                loss --percent 1 zookeeper-west broker-west-1 broker-west-2 &
docker-compose exec -u0 broker-west-2 tc qdisc add dev eth0 root handle 1: prio > /dev/null
docker-compose exec -u0 broker-west-1 tc qdisc add dev eth0 root handle 1: prio > /dev/null
docker-compose exec -u0 zookeeper-west tc qdisc add dev eth0 root handle 1: prio > /dev/null
docker-compose exec -u0 zookeeper-west tc qdisc add dev eth0 parent 1:1 handle 10: sfq > /dev/null
docker-compose exec -u0 broker-west-1 tc qdisc add dev eth0 parent 1:1 handle 10: sfq > /dev/null
docker-compose exec -u0 broker-west-2 tc qdisc add dev eth0 parent 1:1 handle 10: sfq > /dev/null
docker-compose exec -u0 broker-west-1 tc qdisc add dev eth0 parent 1:2 handle 20: sfq > /dev/null
docker-compose exec -u0 zookeeper-west tc qdisc add dev eth0 parent 1:2 handle 20: sfq > /dev/null
docker-compose exec -u0 broker-west-2 tc qdisc add dev eth0 parent 1:2 handle 20: sfq > /dev/null
docker-compose exec -u0 zookeeper-west tc qdisc add dev eth0 parent 1:3 handle 30: netem loss 1.00 > /dev/null
docker-compose exec -u0 broker-west-2 tc qdisc add dev eth0 parent 1:3 handle 30: netem loss 1.00 > /dev/null
docker-compose exec -u0 broker-west-1 tc qdisc add dev eth0 parent 1:3 handle 30: netem loss 1.00 > /dev/null
docker-compose exec -u0 zookeeper-west tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $ZOOKEEPER_EAST_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-west-1 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $ZOOKEEPER_EAST_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-west-2 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $ZOOKEEPER_EAST_IP flowid 1:3 > /dev/null
docker-compose exec -u0 zookeeper-west tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_3_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-west-1 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_3_IP flowid 1:3 > /dev/null
docker-compose exec -u0 zookeeper-west tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_4_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-west-2 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_3_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-west-1 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_4_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-west-2 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_EAST_4_IP flowid 1:3 > /dev/null

echo -e "\n==> Configuring east-west with 1% packet loss"
#docker run --rm -d \
#        --network=${DOCKER_NETWORK} \
#        --name pumba-loss-east-west \
#        -v /var/run/docker.sock:/var/run/docker.sock \
#        -e ZOOKEEPER_WEST_IP=${ZOOKEEPER_WEST_IP} \
#        -e KAFKA_WEST_1_IP=${KAFKA_WEST_1_IP} \
#        -e KAFKA_WEST_2_IP=${KAFKA_WEST_2_IP} \
#        gaiaadm/pumba:0.7.6 -l debug netem --duration 24000h \
#                --tc-image gaiadocker/iproute2 \
#                --target ${ZOOKEEPER_WEST_IP} \
#                --target ${KAFKA_WEST_1_IP} \
#                --target ${KAFKA_WEST_2_IP} \
#                loss --percent 1 zookeeper-east broker-east-3 broker-east-4 &
docker-compose exec -u0 zookeeper-east tc qdisc add dev eth0 root handle 1: prio > /dev/null
docker-compose exec -u0 broker-east-4 tc qdisc add dev eth0 root handle 1: prio > /dev/null
docker-compose exec -u0 broker-east-3 tc qdisc add dev eth0 root handle 1: prio > /dev/null
docker-compose exec -u0 broker-east-4 tc qdisc add dev eth0 parent 1:1 handle 10: sfq > /dev/null
docker-compose exec -u0 zookeeper-east tc qdisc add dev eth0 parent 1:1 handle 10: sfq > /dev/null
docker-compose exec -u0 broker-east-3 tc qdisc add dev eth0 parent 1:1 handle 10: sfq > /dev/null
docker-compose exec -u0 broker-east-4 tc qdisc add dev eth0 parent 1:2 handle 20: sfq > /dev/null
docker-compose exec -u0 zookeeper-east tc qdisc add dev eth0 parent 1:2 handle 20: sfq > /dev/null
docker-compose exec -u0 broker-east-3 tc qdisc add dev eth0 parent 1:2 handle 20: sfq > /dev/null
docker-compose exec -u0 zookeeper-east tc qdisc add dev eth0 parent 1:3 handle 30: netem loss 1.00 > /dev/null
docker-compose exec -u0 broker-east-3 tc qdisc add dev eth0 parent 1:3 handle 30: netem loss 1.00 > /dev/null
docker-compose exec -u0 broker-east-4 tc qdisc add dev eth0 parent 1:3 handle 30: netem loss 1.00 > /dev/null
docker-compose exec -u0 zookeeper-east tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $ZOOKEEPER_WEST_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-east-3 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $ZOOKEEPER_WEST_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-east-4 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $ZOOKEEPER_WEST_IP flowid 1:3 > /dev/null
docker-compose exec -u0 zookeeper-east tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_WEST_1_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-east-4 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_WEST_1_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-east-3 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_WEST_1_IP flowid 1:3 > /dev/null
docker-compose exec -u0 zookeeper-east tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_WEST_2_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-east-4 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_WEST_2_IP flowid 1:3 > /dev/null
docker-compose exec -u0 broker-east-3 tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst $KAFKA_WEST_2_IP flowid 1:3 > /dev/null
