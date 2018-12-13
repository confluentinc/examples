#!/usr/bin/env bash
cd $(dirname "$0")
echo "Loading Clickstream-Demo TABLES to Confluent-Connect => Elastic => Grafana datasource"

declare -a tables=('click_user_sessions' 'user_ip_activity' 'enriched_error_codes_count' 'errors_per_min_alert' 'errors_per_min' 'events_per_min' 'pages_per_min');
for i in "${tables[@]}"
do



    table_name=$i
    TABLE_NAME=`echo $table_name | tr '[a-z]' '[A-Z]'`

    echo -e "\n\n==================================================================" 
    echo -e "Charting " $TABLE_NAME  

    ## Cleanup existing data

    echo -e "\t-> Remove any existing Elastic search config"  
    curl -s -X "DELETE" "http://localhost:9200/""$table_name"  >>/tmp/log.txt 2>&1

    echo -e "\t-> Remove any existing Connect config"  
    curl -s -X "DELETE" "http://localhost:8083/connectors/es_sink_""$TABLE_NAME"  >>/tmp/log.txt 2>&1

    echo -e "\t-> Remove any existing Grafana config"  
    curl -s -X "DELETE" "http://localhost:3000/api/datasources/name/""$table_name"   --user admin:admin  >>/tmp/log.txt 2>&1

    # Wire in the new connection path
    echo -e "\t-> Connecting KSQL->Elastic->Grafana " "$table_name"  2>&1
    ./ksql-connect-es-grafana.sh "$table_name"  2>&1
done

echo -e "\n\nDone!"

# ========================
#   REST API Notes
# ========================
#
# Extract datasources from grafana
# curl -s "http://localhost:3000/api/datasources"  -u admin:admin|jq -c -M '.[]'
#
# Delete a Grafana DataSource
# curl -X "DELETE" "http://localhost:3000/api/datasources/name/

# List confluent connectors
# curl -X "GET" "http://localhost:8083/connectors"
#
# Delete a Confluent-Connector
# curl -X "DELETE" "http://localhost:8083/connectors/es_sink_PER_USER_KBYTES_TS"
#
# Delete an Elastic Index
# curl -X "DELETE" "http://localhost:9200/per_user_kbytes_ts"
#
