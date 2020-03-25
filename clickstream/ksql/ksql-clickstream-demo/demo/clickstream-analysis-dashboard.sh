#!/usr/bin/env bash
#curl -X "GET" "http://localhost:3000/api/dashboards/db/click-stream-analysis" \
#        -H "Content-Type: application/json" \
#	     --user user:user

if [[ -z "${GRAFANA_HOST}" ]]; then
  echo -e "GRAFANA_HOST not set, defaulting to localhost"
  GRAFANA_HOST="localhost"
fi

echo "Loading Grafana ClickStream Dashboard"

RESP="$(curl -s -X "POST" "http://$GRAFANA_HOST:3000/api/dashboards/db" \
	    -H "Content-Type: application/json" \
	     --user user:user \
	     --data-binary @/scripts/clickstream-analysis-dashboard.json)"

#echo $RESP
echo ""
echo ""

if [[ $RESP =~ .*\"url\":\"([^\"]*)\".* ]]
then
    url="${BASH_REMATCH[1]}"
else
    url="/dashboard/db/click-stream-analysis"
fi

#echo -e "Navigate to:\n\thttp://localhost:3000${url}\n(Default user: user / password: user)"
