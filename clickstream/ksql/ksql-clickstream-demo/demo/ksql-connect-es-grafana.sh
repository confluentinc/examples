#!/usr/bin/env bash

## An "all-in-one script" to load up a new table and connect all of the relevant parts to allow data to pipe through from KSQL.KafkaTopic->Connect->Elastic->Grafana[DataSource]
## Accepts a KSQL TABLE_NAME where the data is to be sourced from.

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


if [ "$#" -ne 1 ]; then
    echo "Usage: ksql-connect-es-grafana.sh <TABLENAME>"
    exit;
fi

table_name=$1
TABLE_NAME=`echo $1 | tr '[a-z]' '[A-Z]'`


echo -e "\t-> Connecting:" $table_name

# Tell Kafka to send this Table-Topic to Elastic
# Note the addition of the FilterNulls transform, which converts null values to null records, which Connect ignores.
echo -e "\t\t-> Adding Kafka Connect Elastic Source es_sink_$TABLE_NAME"

curl -s -X "POST" "http://$CONNECT_HOST:8083/connectors/" \
     -H "Content-Type: application/json" \
     -d $'{
  "name": "es_sink_'$TABLE_NAME'",
  "config": {
    "schema.ignore": "true",
    "topics": "'$TABLE_NAME'",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter.schemas.enable": false,
    "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
    "key.ignore": "true",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "type.name": "type.name=kafkaconnect",
    "topic.index.map": "'$TABLE_NAME':'$table_name'",
    "connection.url": "http://'$ELASTIC_HOST':9200",
    "transforms": "FilterNulls",
    "transforms.FilterNulls.type": "io.confluent.transforms.NullFilter"
  }
}' >>/tmp/log.txt 2>&1


echo -e "\t\t-> Adding Grafana Source"

## Add the Elastic DataSource into Grafana
curl -s -X "POST" "http://$GRAFANA_HOST:3000/api/datasources" \
	    -H "Content-Type: application/json" \
	     --user user:user \
	     -d $'{"id":1,"orgId":1,"name":"'$table_name'","type":"elasticsearch","typeLogoUrl":"public/app/plugins/datasource/elasticsearch/img/elasticsearch.svg","access":"proxy","url":"http://'$ELASTIC_HOST':9200","password":"","user":"","database":"'$table_name'","basicAuth":false,"isDefault":false,"jsonData":{"timeField":"EVENT_TS"}}' \
       >>/tmp/log.txt 2>&1
