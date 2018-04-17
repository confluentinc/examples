#!/usr/bin/env bash

LOG_FILE=/tmp/ksql-connect.log
echo "PROCESSING UPLOAD "  > $LOG_FILE

echo "Loading Clickstream-Demo TABLES to Confluent-Connect => Elastic => Grafana datasource"
echo "Logging to:" $LOG_FILE

./elastic-dynamic-template.sh >> $LOG_FILE 2>&1




declare -a tables=('click_user_sessions' 'user_ip_activity' 'enriched_error_codes_count' 'errors_per_min_alert' 'errors_per_min' 'events_per_min_max_avg' 'events_per_min' 'pages_per_min');
for i in "${tables[@]}"
do



    table_name=$i
    TABLE_NAME=`echo $table_name | tr '[a-z]' '[A-Z]'`

    echo "==================================================================" >> $LOG_FILE
    echo "Charting " $TABLE_NAME  >> $LOG_FILE
    echo "Charting " $TABLE_NAME


    ## Cleanup existing data

    echo >> $LOG_FILE
    echo "Remove any existing Elastic search config"  >> $LOG_FILE
    curl -X "DELETE" "http://localhost:9200/""$table_name" >> $LOG_FILE 2>&1

    echo >> $LOG_FILE
    echo "Remove any existing Connect config"  >> $LOG_FILE
    curl -X "DELETE" "http://localhost:8083/connectors/es_sink_""$TABLE_NAME" >> $LOG_FILE 2>&1

    echo >> $LOG_FILE
    echo "Remove any existing Grafana config"  >> $LOG_FILE
    curl -X "DELETE" "http://localhost:3000/api/datasources/name/""$table_name"   --user admin:admin >> $LOG_FILE 2>&1

    # Wire in the new connection path
    echo >> $LOG_FILE
    echo "Connecting KSQL->Elastic->Grafana " "$table_name" >> $LOG_FILE 2>&1
    ./ksql-connect-es-grafana.sh "$table_name" >> $LOG_FILE 2>&1
done

echo "Done"

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
