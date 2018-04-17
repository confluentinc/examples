#!/bin/bash

curl -X PUT -H "kbn-version: 5.5.2" -d '{"title":"wikipediabot","notExpandable":true}' http://localhost:5601/es_admin/.kibana/index-pattern/wikipediabot/_create 
curl -X POST -H "kbn-version: 5.5.2" -H "Content-Type: application/json;charset=UTF-8" -d '{"value":"wikipediabot"}' http://localhost:5601/api/kibana/settings/timelion:es.default_index
curl -X POST -H "kbn-version: 5.5.2" -H "Content-Type: application/json;charset=UTF-8" -d '{"value":"CREATEDAT"}' http://localhost:5601/api/kibana/settings/timelion:es.timefield
curl -X POST -H "kbn-version: 5.5.2" -H "Content-Type: application/json;charset=UTF-8" -d '{"value":"wikipediabot"}' http://localhost:5601/api/kibana/settings/defaultIndex
curl -X PUT -H "kbn-version: 5.5.2" -d '{"title":"en_wikipedia_gt_1","notExpandable":true}' http://localhost:5601/es_admin/.kibana/index-pattern/en_wikipedia_gt_1/_create 
curl --silent --output /dev/null -X POST -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @dashboard/kibana_dash.json http://localhost:5601/api/kibana/dashboards/import
#curl -X POST -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @dashboard/kibana_dash.json http://localhost:5601/api/kibana/dashboards/import

#curl -X GET http://localhost:5601/api/kibana/dashboards/export?dashboard=Wikipedia > /tmp/dash.json
