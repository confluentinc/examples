#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
    "settings": {
        "number_of_shards": 1
    },
    "mappings": {
        "wikichange": {
            "properties": {
                "ROWTIME": {
                    "type": "text"
                },
                "ROWKEY": {
                    "type": "text"
                },
                "WIKIPAGE": {
                    "type": "keyword"
                },
                "USERNAME": {
                    "type": "keyword"
                },
                "COUNT": {
                    "type": "integer"
                }
            }
        }
    }
}

EOF);

curl -XDELETE http://localhost:9200/en_wikipedia_gt_1 &> /dev/null
curl -XPUT -H "${HEADER}" --data "${DATA}" 'http://localhost:9200/en_wikipedia_gt_1?pretty'
echo
