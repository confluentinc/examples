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
                "CREATEDAT": {
                    "type": "date"
                },
                "WIKIPAGE": {
                    "type": "keyword"
                },
                "ISNEW": {
                    "type": "boolean"
                },
                "ISMINOR": {
                    "type": "boolean"
                },
                "ISUNPATROLLED": {
                    "type": "boolean"
                },
                "ISBOT": {
                    "type": "boolean"
                },
                "DIFFURL": {
                    "type": "text"
                },
                "USERNAME": {
                    "type": "keyword"
                },
                "BYTECHANGE": {
                    "type": "integer"
                },
                "COMMITMESSAGE": {
                    "type": "text"
                }
            }
        }
    }
}

EOF);

curl -XPUT -H "${HEADER}" --data "${DATA}" 'http://localhost:9200/wikipediabot?pretty'
echo
