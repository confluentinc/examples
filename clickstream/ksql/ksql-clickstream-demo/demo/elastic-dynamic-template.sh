#!/usr/bin/env bash

if [[ -z "${ELASTIC_HOST}" ]]; then
  echo -e "ELASTIC_HOST not set, defaulting to localhost"
  ELASTIC_HOST="localhost"
fi


echo -e "\n-> Removing kafkaconnect template if it exists already."

curl -s -XDELETE "http://$ELASTIC_HOST:9200/_template/kafkaconnect/" > /tmp/log.txt

echo -e "\n\n-> Loading Elastic Dynamic Template to ensure _TS fields are used for TimeStamp\n\n"

curl -XPUT "http://$ELASTIC_HOST:9200/_template/kafkaconnect/" -H 'Content-Type: application/json' -d'
{
  "template": "*",
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "_default_": {
      "dynamic_templates": [
        {
          "dates": {
            "match": "EVENT_TS",
            "mapping": {
              "type": "date"
            }
          }
        },
        {
          "non_analysed_string_template": {
            "match": "*",
            "match_mapping_type": "string",
            "mapping": {
              "type": "keyword"
            }
          }}
      ]
    }
  }
}'