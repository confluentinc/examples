#!/bin/bash
export DOCKER_NETWORK=multiregion_n1
export ZOOKEEPER_EAST_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' zookeeper-east)
export KAFKA_EAST_3_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-east-3)
export KAFKA_EAST_4_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-east-4)

export SUBNET=$(docker inspect multiregion_n1 -f '{{(index .IPAM.Config 0).Subnet}}')

echo -e "\n==> Running container pumba-zk-central for low latency link\n"

# Create low latency link (50ms) to zookeeper-central
docker run --rm -d \
	--network=${DOCKER_NETWORK} \
	--name pumba-zk-central \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e SUBNET=${SUBNET} \
	gaiaadm/pumba:0.6.4 netem --duration 30m \
  		--target $SUBNET \
                delay --time 50 zookeeper-central --jitter 10 &

echo -e "\n==> Running container pumba-delay for high latency link\n"

# Create high latency link (100ms) from west to east
docker run --rm -d \
	--network=${DOCKER_NETWORK} \
	--name pumba-delay \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e ZOOKEEPER_EAST_IP=${ZOOKEEPER_EAST_IP} \
	-e KAFKA_EAST_3_IP=${KAFKA_EAST_3_IP} \
	-e KAFKA_EAST_4_IP=${KAFKA_EAST_4_IP} \
	gaiaadm/pumba:0.6.4 netem --duration 30m \
		--target ${ZOOKEEPER_EAST_IP} \
		--target ${KAFKA_EAST_3_IP} \
		--target ${KAFKA_EAST_4_IP} \
        	delay --time 100 zookeeper-west broker-west-1 broker-west-2 --jitter 20 &

echo -e "\n==> Running container pumba-rate-limit\n"

# Limit bandwidth from west to 1kbps
docker run --rm -d \
	--network=${DOCKER_NETWORK} \
	--name pumba-rate-limit \
	-v /var/run/docker.sock:/var/run/docker.sock \
	gaiaadm/pumba:0.6.4 netem --duration 30m \
		rate --rate 1kbit zookeeper-west broker-west-1 broker-west-2
