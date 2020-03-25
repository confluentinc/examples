#!/usr/bin/env bash
cd $(dirname "$0")
echo "Loading Clickstream-Demo TABLES to Kafka Connect => Elastic => Grafana datasource"

if [[ -z "${CONNECT_HOST}" ]]; then
  echo -e "CONNECT_HOST not set, defaulting to localhost"
  CONNECT_HOST="localhost"
fi
if [[ -z "${GRAFANA_HOST}" ]]; then
  echo -e "GRAFANA_HOST not set, defaulting to localhost"
  GRAFANA_HOST="localhost"
fi
if [[ -z "${ELASTIC_HOST}" ]]; then
  echo -e "ELASTIC_HOST not set, defaulting to localhost"
  ELASTIC_HOST="localhost"
fi

declare -a tables=('click_user_sessions' 'user_ip_activity' 'enriched_error_codes_count' 'errors_per_min_alert' 'errors_per_min' 'events_per_min' 'pages_per_min');
for i in "${tables[@]}"
do
    table_name=$i
    TABLE_NAME=`echo $table_name | tr '[a-z]' '[A-Z]'`

    echo -e "\n\n==================================================================" 
    echo -e "Charting " $TABLE_NAME  

    ## Cleanup existing data

    echo -e "\t-> Remove any existing Elastic search config"  
    curl -s -X "DELETE" "http://$ELASTIC_HOST:9200/""$table_name"  >>/tmp/log.txt 2>&1

    echo -e "\t-> Remove any existing Connect config"  
    curl -s -X "DELETE" "http://$CONNECT_HOST:8083/connectors/es_sink_""$TABLE_NAME"  >>/tmp/log.txt 2>&1

    echo -e "\t-> Remove any existing Grafana config"  
    curl -s -X "DELETE" "http://$GRAFANA_HOST:3000/api/datasources/name/""$table_name"   --user user:user  >>/tmp/log.txt 2>&1

    # Wire in the new connection path
    echo -e "\t-> Connecting ksqlDB->Elastic->Grafana" "$table_name"  2>&1
    ./ksql-connect-es-grafana.sh "$table_name"  2>&1
done

echo -e "\n\nDone!"

# ========================
#   REST API Notes
# ========================
#
# Extract datasources from grafana
# curl -s "http://$GRAFANA_HOST:3000/api/datasources"  -u user:user|jq -c -M '.[]'
#
# Delete a Grafana DataSource
# curl -X "DELETE" "http://$GRAFANA_HOST:3000/api/datasources/name/

# List confluent connectors
# curl -X "GET" "http://$CONNECT_HOST:8083/connectors"
#
# Delete a Confluent-Connector
# curl -X "DELETE" "http://$CONNECT_HOST:8083/connectors/es_sink_PER_USER_KBYTES_TS"
#
# Delete an Elastic Index
# curl -X "DELETE" "http://$ELASTIC_HOST:9200/per_user_kbytes_ts"
#
