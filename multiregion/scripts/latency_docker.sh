#!/bin/bash
export DOCKER_NETWORK=multiregion_n1
export ZOOKEEPER_WEST_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' zookeeper-west)
export ZOOKEEPER_EAST_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' zookeeper-east)
export KAFKA_WEST_1_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-west-1)
export KAFKA_WEST_2_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-west-2)
export KAFKA_EAST_3_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-east-3)
export KAFKA_EAST_4_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' broker-east-4)

export SUBNET=$(docker inspect multiregion_n1 -f '{{(index .IPAM.Config 0).Subnet}}')

echo -e "\n==> Running container pumba-medium-latency-central for medium latency link (50ms)\n"

# Create medium latency link (50ms) to zookeeper-central
docker run --rm -d \
	--network=${DOCKER_NETWORK} \
	--name pumba-medium-latency-central \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e SUBNET=${SUBNET} \
	gaiaadm/pumba:0.6.4 netem --duration 30m \
  		--target $SUBNET \
                delay --time 50 zookeeper-central --jitter 10 &

echo -e "\n==> Running container pumba-high-latency-west-east for high latency link (100ms)\n"

# Create high latency link (100ms) from west to east
docker run --rm -d \
	--network=${DOCKER_NETWORK} \
	--name pumba-high-latency-west-east \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e ZOOKEEPER_EAST_IP=${ZOOKEEPER_EAST_IP} \
	-e KAFKA_EAST_3_IP=${KAFKA_EAST_3_IP} \
	-e KAFKA_EAST_4_IP=${KAFKA_EAST_4_IP} \
	gaiaadm/pumba:0.6.4 netem --duration 30m \
		--target ${ZOOKEEPER_EAST_IP} \
		--target ${KAFKA_EAST_3_IP} \
		--target ${KAFKA_EAST_4_IP} \
        	delay --time 100 zookeeper-west broker-west-1 broker-west-2 --jitter 20 &

echo -e "\n==> Running container pumba-loss-west-east with 1% packet loss from west to east\n"

docker run --rm -d \
	--network=${DOCKER_NETWORK} \
	--name pumba-loss-west-east \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e ZOOKEEPER_EAST_IP=${ZOOKEEPER_EAST_IP} \
	-e KAFKA_EAST_3_IP=${KAFKA_EAST_3_IP} \
	-e KAFKA_EAST_4_IP=${KAFKA_EAST_4_IP} \
	gaiaadm/pumba:0.6.4 netem --duration 30m \
		--target ${ZOOKEEPER_EAST_IP} \
		--target ${KAFKA_EAST_3_IP} \
		--target ${KAFKA_EAST_4_IP} \
		loss --percent 1 zookeeper-west broker-west-1 broker-west-2 &

echo -e "\n==> Running container pumba-loss-east-west with 1% packet loss from east to west\n"

docker run --rm -d \
	--network=${DOCKER_NETWORK} \
	--name pumba-loss-east-west \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e ZOOKEEPER_WEST_IP=${ZOOKEEPER_WEST_IP} \
	-e KAFKA_WEST_1_IP=${KAFKA_WEST_1_IP} \
	-e KAFKA_WEST_2_IP=${KAFKA_WEST_2_IP} \
	gaiaadm/pumba:0.6.4 netem --duration 30m \
		--target ${ZOOKEEPER_WEST_IP} \
		--target ${KAFKA_WEST_1_IP} \
		--target ${KAFKA_WEST_2_IP} \
		loss --percent 1 zookeeper-east broker-east-3 broker-east-4 &
