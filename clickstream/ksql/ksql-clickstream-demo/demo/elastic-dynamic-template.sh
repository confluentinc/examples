#!/usr/bin/env bash

echo "Loading Elastic Dynamic Template to ensure _TS fields are used for TimeStamp"

curl -XDELETE "http://localhost:9200/_template/kafkaconnect/"

curl -XPUT "http://localhost:9200/_template/kafkaconnect/" -H 'Content-Type: application/json' -d'
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
              "type": "keyword",
              "index": "not_analyzed"
            }
          }
        }
      ]
    }
  }
}'