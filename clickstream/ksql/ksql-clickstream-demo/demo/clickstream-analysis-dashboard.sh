#!/usr/bin/env bash
#curl -X "GET" "http://localhost:3000/api/dashboards/db/click-stream-analysis" \
#        -H "Content-Type: application/json" \
#	     --user admin:admin


echo "Loading Grafana ClickStream Dashboard"

RESP="$(curl -X "POST" "http://localhost:3000/api/dashboards/db" \
	    -H "Content-Type: application/json" \
	     --user admin:admin \
	     --data-binary @clickstream-analysis-dashboard.json)"

echo $RESP
echo ""
echo ""

if [[ $RESP =~ .*\"url\":\"([^\"]*)\".* ]]
then
    url="${BASH_REMATCH[1]}"
else
    url="/dashboard/db/click-stream-analysis"
fi

echo "Navigate to:"
echo "  http://localhost:3000${url} (non-docker)"
echo "or"
echo "  http://localhost:33000${url} (docker)"