#!/bin/bash

DASHBOARD_PATH=${DASHBOARD_PATH:-/opt/docker/dashboard/kibana_dashboard_microservices.json}
ELASTICSEARCH_URL=${ELASTICSEARCH_URL:-http://elasticsearch:9200}
KIBANA_URL=${KIBANA_URL:-http://kibana:5601}
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

curl -s -S -XDELETE "$ELASTICSEARCH_URL/orders"
curl -s -S -XPUT -H "${HEADER}" --data "${DATA}" "$ELASTICSEARCH_URL/orders?pretty"

curl -s -S -XPUT -H 'kbn-version: 5.5.2' -d '{"title":"orders","notExpandable":true}' $KIBANA_URL/es_admin/.kibana/index-pattern/orders/_create 
curl -s -S -XPOST -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @"$DASHBOARD_PATH" $KIBANA_URL/api/kibana/dashboards/import
