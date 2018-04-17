#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF

{
  "settings": {
      "number_of_shards": 1
  },
  "mappings": {
    "ratings_enriched": {
      "dynamic_templates": [
        {
          "dates": {
            "match": "EXTRACT_TS",
            "mapping": {
              "type": "date"
            }
          }
        }
      ],
      "properties": {
        "CHANNEL": {
          "type": "keyword",
          "index": true
        },
        "EXTRACT_TS": {
          "type": "date"
        },
        "FULL_NAME": {
          "type": "keyword",
          "index": true
        },
        "MESSAGE": {
          "type": "keyword",
          "index": true
        },
        "ID": {
          "type": "long"
        },
        "RATING_ID": {
          "type": "long"
        }
      }
    }
  }
}

EOF);

curl --silent --output /dev/null -XPUT -H "${HEADER}" --data "${DATA}" 'http://localhost:9200/ratings_enriched?pretty'
echo
