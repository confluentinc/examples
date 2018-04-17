#!/bin/bash

curl --silent --output /dev/null -X PUT -H "kbn-version: 5.5.2" -d '{"title":"ratings_enriched","notExpandable":true}' http://localhost:5601/es_admin/.kibana/index-pattern/ratings_enriched/_create 
curl --silent --output /dev/null -X POST -H "kbn-version: 5.5.2" -H "Content-Type: application/json;charset=UTF-8" -d '{"value":"ratings_enriched"}' http://localhost:5601/api/kibana/settings/timelion:es.default_index
curl --silent --output /dev/null -X POST -H "kbn-version: 5.5.2" -H "Content-Type: application/json;charset=UTF-8" -d '{"value":"ratings_enriched"}' http://localhost:5601/api/kibana/settings/defaultIndex
curl --silent --output /dev/null -X POST -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @dashboard/kibana_dash.json http://localhost:5601/api/kibana/dashboards/import
