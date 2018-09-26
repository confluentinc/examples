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

EOF
);

curl -XDELETE http://elasticsearch:9200/orders
curl -XPUT -H "${HEADER}" --data "${DATA}" 'http://elasticsearch:9200/orders?pretty'

curl -X PUT -H "kbn-version: 5.5.2" -d '{"title":"orders","notExpandable":true}' http://kibana:5601/es_admin/.kibana/index-pattern/orders/_create 
curl -X POST -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @/tmp/dashboard/kibana_dashboard_microservices.json http://kibana:5601/api/kibana/dashboards/import
