#!/usr/bin/env bash
#curl -X "GET" "http://localhost:3000/api/dashboards/db/click-stream-analysis" \
#        -H "Content-Type: application/json" \
#	     --user user:user

if [[ -z "${GRAFANA_HOST}" ]]; then
  echo -e "GRAFANA_HOST not set, defaulting to localhost"
  GRAFANA_HOST="localhost"
fi


echo "Loading Grafana ClickStream Dashboard"

curl -X "POST" "http://'$GRAFANA_HOST':3000/api/dashboards/db" \
	    -H "Content-Type: application/json" \
	     --user user:user \
	     --data-binary @malicious-users-dashboard.json

