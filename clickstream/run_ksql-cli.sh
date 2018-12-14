#!/bin/sh
export KSQL_SERVER=ksql-server
export KSQL_SERVER_REST_PORT=8088

docker-compose exec ksql-cli bash -c 'echo -e "\n\n⏳ Waiting for KSQL Server to be available before launching CLI\n"; while [ $(curl -s -o /dev/null -w %{http_code} http://'$KSQL_SERVER':'$KSQL_SERVER_REST_PORT'/) -eq 000 ] ; do echo -e $(date) "KSQL Server HTTP state: " $(curl -s -o /dev/null -w %{http_code} http://'$KSQL_SERVER':'$KSQL_SERVER_REST_PORT'/) " (waiting for 200)" ; sleep 5 ; done; ksql http://'$KSQL_SERVER':'$KSQL_SERVER_REST_PORT