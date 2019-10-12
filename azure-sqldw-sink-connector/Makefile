build:
	docker-compose build --force-rm

cluster:
	docker-compose up -d

sqldw:
	sed -i '' 's/_SERVER_/${SERVER}/g' azure.sqldw.json 
	sed -i '' 's/_ADMIN_USER_/${ADMIN_USER}/g' azure.sqldw.json 
	sed -i '' 's/_ADMIN_PASS_/${ADMIN_PASS}/g' azure.sqldw.json 
	sed -i '' 's/_DWNAME_/${DWNAME}/g' azure.sqldw.json 

	az sql server create \
		--name ${SERVER} \
		--resource-group ${RESOURCE_GROUP} \
		--location ${REGION} \
		--admin-user ${ADMIN_USER} \
		--admin-password ${ADMIN_PASS}

	az sql server firewall-rule create \
		--name quickstartFirewallRule \
		--resource-group ${RESOURCE_GROUP} \
		--server ${SERVER} \
		--start-ip-address ${IP_ADDRESS} \
		--end-ip-address ${IP_ADDRESS}

	az sql dw create \
		--name ${DWNAME} \
		--resource-group ${RESOURCE_GROUP} \
		--server ${SERVER}

ps:
	docker-compose ps

down:
	docker-compose down
	az group delete --name ${RESOURCE_GROUP}

topic:
	docker exec -it connect kafka-topics --bootstrap-server broker:29092 --create --topic clickstream --partitions 1 --replication-factor 1

connect:
	docker exec -it connect curl -d "@/project/azure.sqldw.json" \
		-X PUT \
		-H "Content-Type: application/json" \
		http://connect:8083/connectors/azure-sqldw-sink/config 

	docker exec -it connect curl -d "@/project/clickstream-connector.json" \
		-X PUT \
		-H "Content-Type: application/json" \
		http://connect:8083/connectors/clickstream/config 

test:
	sed -i '' 's/_SERVER_/${SERVER}/g' azure.sqldw.json 
	