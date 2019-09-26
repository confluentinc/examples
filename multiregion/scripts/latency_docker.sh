#!/bin/bash
export DOCKER_NETWORK=multiregion_n1
export ZOOKEEPER_EAST_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' zookeeper-east)
export KAFKA_EAST_1_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-east-3)
export KAFKA_EAST_2_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-east-4)

export SUBNET=$(docker inspect multiregion_n1 -f '{{(index .IPAM.Config 0).Subnet}}')

echo -e "\n==> Running pumba containers for latency\n"

# Create low latency link (50ms) to zookeeper-central
docker run -d \
	--network=${DOCKER_NETWORK} \
	--name pumba-zk-central \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e SUBNET=${SUBNET} \
	gaiaadm/pumba:0.6.4 netem --duration 30m \
  		--target $SUBNET delay --time 50 zookeeper-central --jitter 10 &

# Create high latency link (100ms) from west to east
docker run -d \
	--network=${DOCKER_NETWORK} \
	--name pumba-delay \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e ZOOKEEPER_EAST_IP=${ZOOKEEPER_EAST_IP} \
	-e KAFKA_EAST_1_IP=${KAFKA_EAST_1_IP} \
	-e KAFKA_EAST_2_IP=${KAFKA_EAST_2_IP} \
	gaiaadm/pumba:0.6.4 netem --duration 30m \
		--target ${ZOOKEEPER_EAST_IP} \
		--target ${KAFKA_EAST_1_IP} \
		--target ${KAFKA_EAST_2_IP} \
        	delay --time 100 zookeeper-west broker-west-1 broker-west-2 --jitter 20 &

# Limit bandwidth from west to 100bps
docker run -d \
	--network=${DOCKER_NETWORK} \
	--name pumba-rate-limit \
	-v /var/run/docker.sock:/var/run/docker.sock \
	gaiaadm/pumba:0.6.4 netem --duration 30m \
		rate --rate 100bit zookeeper-west broker-west-1 broker-west-2
