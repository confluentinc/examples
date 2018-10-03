#!/bin/bash

cat /etc/hosts

echo "test1"
curl -X PUT -H "kbn-version: 5.5.2" -d '{"title":"orders","notExpandable":true}' http://kibana:5601/es_admin/.kibana/index-pattern/orders/_create 
echo "test2"
curl -X POST -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @/tmp/dashboard/kibana_dashboard_microservices.json http://kibana:5601/api/kibana/dashboards/import
echo "test3"
