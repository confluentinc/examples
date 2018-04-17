#!/usr/bin/env bash
#curl -X "GET" "http://localhost:3000/api/dashboards/db/click-stream-analysis" \
#        -H "Content-Type: application/json" \
#	     --user admin:admin


echo "Loading Grafana ClickStream Dashboard"

curl -X "POST" "http://localhost:3000/api/dashboards/db" \
	    -H "Content-Type: application/json" \
	     --user admin:admin \
	     --data-binary @malicious-users-dashboard.json

