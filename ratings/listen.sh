echo "\nmysql_users:"
kafka-console-consumer \
--bootstrap-server localhost:9092 \
--topic mysql_users \
--from-beginning \
--property print.key=true \
--max-messages 5 

echo "\nPOOR_RATINGS:"
kafka-avro-console-consumer \
--bootstrap-server localhost:9092 \
--property schema.registry.url=http://localhost:8081 \
--topic POOR_RATINGS \
--from-beginning --max-messages 5 | jq '.'

echo "\nUNHAPPY_VIPS:"
kafka-avro-console-consumer \
--bootstrap-server localhost:9092 \
--property schema.registry.url=http://localhost:8081 \
--topic UNHAPPY_VIPS --from-beginning --max-messages 5 | jq '.'

echo "\nRATINGS_BY_CITY:"
kafka-avro-console-consumer \
--bootstrap-server localhost:9092 \
--property schema.registry.url=http://localhost:8081 \
--topic RATINGS_BY_CITY --from-beginning -max-messages 5 | jq '.'

echo "\nRATINGS_BY_CITY_TS:"
kafka-avro-console-consumer \
--bootstrap-server localhost:9092 \
--property schema.registry.url=http://localhost:8081 \
--topic RATINGS_BY_CITY_TS --from-beginning --max-messages 5| jq '.'
