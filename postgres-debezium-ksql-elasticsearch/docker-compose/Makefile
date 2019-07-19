cluster:
	docker-compose up -d

status:
	docker-compose logs -f kafka-connect-cp|grep "Kafka Connect started"

setup:
	scripts/setup.sh

down:
	docker-compose down

ps:
	docker-compose ps

psql:
	docker-compose exec postgres bash -c 'psql --username postgres'

ksql:
	docker-compose exec ksql-cli ksql http://ksql-server:8088

clist:
	docker exec -it connect-debezium curl http://connect-debezium:8083/connectors | jq

