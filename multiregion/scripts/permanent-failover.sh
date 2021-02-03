echo -e "\n==> Switching replica placement constraints for multi-region-default\n"

docker-compose exec broker-east-3 kafka-configs \
	--bootstrap-server broker-east-3:19093 \
	--alter \
	--topic multi-region-default \
	--replica-placement /etc/kafka/demo/placement-multi-region-default-reverse.json


echo -e "\n==> Running Confluent Rebalancer on multi-region-default\n"

docker-compose exec broker-east-3 confluent-rebalancer execute \
	--metrics-bootstrap-server broker-ccc:19098 \
	--bootstrap-server broker-east-3:19093 \
	--replica-placement-only \
	--topics multi-region-default \
	--force \
	--throttle 10000000

docker-compose exec broker-east-3 confluent-rebalancer finish \
	--bootstrap-server broker-east-3:19093
