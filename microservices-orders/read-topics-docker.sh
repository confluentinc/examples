#!/bin/bash

################################

echo -e "\n*** Sampling messages in Kafka topics and a KSQL stream ***\n"

# Topic customers: populated by Kafka Connect that uses the JDBC source connector to read customer data from a sqlite3 database
echo -e "\n-----customers-----"
docker-compose exec connect kafka-avro-console-consumer --bootstrap-server broker:9092 --topic customers --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.LongDeserializer --property schema.registry.url=http://schema-registry:8081 --from-beginning --max-messages 5

# Topic orders: populated by a POST to the OrdersService service. A unique order is requested 1 per second
echo -e "\n-----orders-----"
docker-compose exec connect kafka-avro-console-consumer --bootstrap-server broker:9092 --topic orders --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --property schema.registry.url=http://schema-registry:8081 --from-beginning --max-messages 5 

# Topic payments: populated by PostOrdersAndPayments writing to the topic after placing an order. One payment is made per order
echo -e "\n-----payments-----"
docker-compose exec connect kafka-avro-console-consumer --bootstrap-server broker:9092 --topic payments --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --property schema.registry.url=http://schema-registry:8081 --from-beginning --max-messages 5

# Topic order-validations: PASS/FAIL for each "checkType": ORDER_DETAILS_CHECK (OrderDetailsService), FRAUD_CHECK (FraudService), INVENTORY_CHECK (InventoryService)
echo -e "\n-----order-validations-----"
docker-compose exec connect kafka-avro-console-consumer --bootstrap-server broker:9092 --topic order-validations --property schema.registry.url=http://schema-registry:8081 --from-beginning --max-messages 15

# Topic warehouse-inventory: initial inventory in stock
echo -e "\n-----warehouse-inventory-----"
docker-compose exec connect kafka-console-consumer --bootstrap-server broker:9092 --topic warehouse-inventory --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.IntegerDeserializer --from-beginning --max-messages 2

# Topic InventoryService-store-of-reserved-stock-changelog: table backing the reserved inventory
# It maxes out when orders = initial inventory
echo -e "\n-----InventoryService-store-of-reserved-stock-changelog-----"
docker-compose exec connect kafka-console-consumer --bootstrap-server broker:9092 --topic InventoryService-store-of-reserved-stock-changelog --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer -from-beginning --from-beginning --max-messages 5

# Read queries
docker-compose exec ksql-cli bash -c "ksql http://ksql-server:8088 <<EOF
SELECT * FROM orders_cust1_joined LIMIT 3;
SELECT * FROM FRAUD_ORDER LIMIT 2;
exit ;
EOF"
