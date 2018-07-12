#!/bin/sh
curl -XPOST "http://localhost:9200/logon_enriched/type.name=kafkaconnect" -H 'Content-Type: application/json' -d'{
  "LOGON_ID": 24487,
  "C_CUSTOMER_ID": 9284,
  "CUST_FULL_NAME": "clark francis",
  "CUSTOMER_SINCE": 1155859200000,
  "CUSTOMER_CLASS": "Business",
  "CREDIT_LIMIT": 4000,
  "EXTRACT_TS": 1529915638000
}'

curl -XPOST "http://localhost:9200/orders/type.name=kafkaconnect" -H 'Content-Type: application/json' -d'
{
  "ORDER_ID": 1856,
  "ORDER_DATE": 1207609200000,
  "ORDER_MODE": "online",
  "CUSTOMER_ID": 1114,
  "ORDER_STATUS": 5,
  "ORDER_TOTAL": 5481,
  "SALES_REP_ID": 548,
  "PROMOTION_ID": 548,
  "WAREHOUSE_ID": 799,
  "DELIVERY_TYPE": "Express",
  "COST_OF_DELIVERY": 2,
  "WAIT_TILL_ALL_AVAILABLE": "ship_when_ready",
  "DELIVERY_ADDRESS_ID": 7,
  "CUSTOMER_CLASS": "Regular",
  "CARD_ID": 4005,
  "INVOICE_ADDRESS_ID": 7,
  "messagetopic": "ora-soe-ORDERS",
  "messagesource": "Oracle 12.2 on asgard",
  "EXTRACT_TS": 1529918349501
}'
