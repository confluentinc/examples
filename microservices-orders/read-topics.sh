#!/bin/bash

################################

echo -e "\n*** Sampling messages in Kafka topics and a KSQL stream ***\n"

# Topic customers: populated by Kafka Connect that uses the JDBC source connector to read customer data from a sqlite3 database
echo -e "\n-----customers-----"
confluent consume customers --value-format avro --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.LongDeserializer --from-beginning --max-messages 5

# Topic orders: populated by a POST to the OrdersService service. A unique order is requested 1 per second
echo -e "\n-----orders-----"
confluent consume orders --value-format avro --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --from-beginning --max-messages 5 

# Topic payments: populated by PostOrdersAndPayments writing to the topic after placing an order. One payment is made per order
echo -e "\n-----payments-----"
confluent consume payments --value-format avro --property print.key=true --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --from-beginning --max-messages 5

# Topic order-validations: PASS/FAIL for each "checkType": ORDER_DETAILS_CHECK (OrderDetailsService), FRAUD_CHECK (FraudService), INVENTORY_CHECK (InventoryService)
echo -e "\n-----order-validations-----"
confluent consume order-validations --value-format avro --from-beginning --max-messages 15

# Topic warehouse-inventory: initial inventory in stock
echo -e "\n-----warehouse-inventory-----"
confluent consume warehouse-inventory --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.IntegerDeserializer --from-beginning --max-messages 2

# Topic InventoryService-store-of-reserved-stock-changelog: table backing the reserved inventory
# It maxes out when orders = initial inventory
echo -e "\n-----InventoryService-store-of-reserved-stock-changelog-----"
confluent consume InventoryService-store-of-reserved-stock-changelog --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer -from-beginning --from-beginning --max-messages 5

# Read queries
ksql http://localhost:8088 <<EOF
SELECT * FROM orders_cust1_joined LIMIT 2;
SELECT * FROM FRAUD_ORDER LIMIT 2;
exit ;
EOF
