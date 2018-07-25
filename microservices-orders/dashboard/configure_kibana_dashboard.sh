#!/bin/bash

curl -X PUT -H "kbn-version: 5.5.2" -d '{"title":"orders","notExpandable":true}' http://localhost:5601/es_admin/.kibana/index-pattern/orders/_create 
curl --silent --output /dev/null -X POST -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @dashboard/kibana_dashboard_microservices.json http://localhost:5601/api/kibana/dashboards/import
