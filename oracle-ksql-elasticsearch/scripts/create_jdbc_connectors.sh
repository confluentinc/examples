#!/bin/sh

curl -i -X POST -H "Accept:application/json" \
  -H  "Content-Type:application/json" http://localhost:18083/connectors/ \
  -d '{
        "name": "jdbc_source_oracle_soe_logon",
        "config": {
                "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
                "connection.url": "jdbc:oracle:thin:soe/soe@oracle:1521/ORCLPDB1",
                "mode": "incrementing",
                "query": "SELECT CAST(LOGON_ID AS NUMERIC(8,0)) AS LOGON_ID, CAST(CUSTOMER_ID AS NUMERIC(18,0)) AS CUSTOMER_ID, LOGON_DATE FROM LOGON",
                "poll.interval.ms": "1000",
                "incrementing.column.name":"LOGON_ID",
                "topic.prefix": "ora-soe-LOGON",
                "validate.non.null":false,
                "transforms":"InsertTopic,InsertSourceDetails",
                "transforms.InsertTopic.type":"org.apache.kafka.connect.transforms.InsertField$Value",
                "transforms.InsertTopic.topic.field":"messagetopic",
                "transforms.InsertSourceDetails.type":"org.apache.kafka.connect.transforms.InsertField$Value",
                "transforms.InsertSourceDetails.static.field":"messagesource",
                "transforms.InsertSourceDetails.static.value":"Oracle 12.2 on asgard","numeric.mapping":"best_fit"
        }
}'

curl -i -X POST -H "Accept:application/json" \
  -H  "Content-Type:application/json" http://localhost:18083/connectors/ \
  -d '{
        "name": "jdbc_source_oracle_soe_orders",
        "config": {
                "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
                "connection.url": "jdbc:oracle:thin:soe/soe@oracle:1521/ORCLPDB1",
                "query":"SELECT ORDER_ID, CAST(ORDER_DATE AS TIMESTAMP) AS ORDER_DATE, ORDER_MODE, CUSTOMER_ID, ORDER_STATUS, ORDER_TOTAL, SALES_REP_ID, PROMOTION_ID, WAREHOUSE_ID, DELIVERY_TYPE, COST_OF_DELIVERY, WAIT_TILL_ALL_AVAILABLE, DELIVERY_ADDRESS_ID, CUSTOMER_CLASS, CARD_ID, INVOICE_ADDRESS_ID FROM ORDERS",
                "mode": "incrementing",
                "poll.interval.ms": "1000",
                "numeric.mapping":"best_fit",
                "incrementing.column.name":"ORDER_ID",
                "topic.prefix": "ora-soe-ORDERS",
                "transforms":"InsertTopic,InsertSourceDetails",
                "transforms.InsertTopic.type":"org.apache.kafka.connect.transforms.InsertField$Value",
                "transforms.InsertTopic.topic.field":"messagetopic",
                "transforms.InsertSourceDetails.type":"org.apache.kafka.connect.transforms.InsertField$Value",
                "transforms.InsertSourceDetails.static.field":"messagesource",
                "transforms.InsertSourceDetails.static.value":"Oracle 12.2 on asgard"
        }
}'

curl -i -X POST -H "Accept:application/json" \
  -H  "Content-Type:application/json" http://localhost:18083/connectors/ \
  -d '{
        "name": "jdbc_source_oracle_soe_customers",
        "config": {
                "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
                "connection.url": "jdbc:oracle:thin:soe/soe@oracle:1521/ORCLPDB1",
                "table.whitelist":"CUSTOMERS",
                "mode": "incrementing",
                "poll.interval.ms": "1000",
                "numeric.mapping":"best_fit",
                "incrementing.column.name":"CUSTOMER_ID",
                "topic.prefix": "ora-soe-",
                "transforms":"InsertTopic,InsertSourceDetails",
                "transforms.InsertTopic.type":"org.apache.kafka.connect.transforms.InsertField$Value",
                "transforms.InsertTopic.topic.field":"messagetopic",
                "transforms.InsertSourceDetails.type":"org.apache.kafka.connect.transforms.InsertField$Value",
                "transforms.InsertSourceDetails.static.field":"messagesource",
                "transforms.InsertSourceDetails.static.value":"Oracle 12.2 on asgard"
        }
}'
