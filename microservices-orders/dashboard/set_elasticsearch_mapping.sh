#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
    "settings": {
        "number_of_shards": 1
    },
    "mappings": {
        "microservices": {
            "properties": {
                "id": {
                    "type": "text"
                },
                "customerid": {
                    "type": "integer"
                },
                "state": {
                    "type": "keyword"
                },
                "product": {
                    "type": "keyword"
                },
                "quantity": {
                    "type": "integer"
                },
                "price": {
                    "type": "integer"
                }
            }
        }
    }
}

EOF);

curl -XDELETE http://localhost:9200/orders &> /dev/null
curl -XPUT -H "${HEADER}" --data "${DATA}" 'http://localhost:9200/orders?pretty'
echo
