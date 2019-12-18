#!/bin/sh

docker-compose exec connect-debezium bash -c '/scripts/create-pg-source.sh'
docker-compose exec kafka-connect-cp bash -c '/scripts/create-pg-sink.sh'
docker-compose exec elasticsearch bash -c '/scripts/create-dynamic-mapping.sh'
docker-compose exec kafka-connect-cp bash -c '/scripts/create-es-sink.sh'
curl -XPOST "http://localhost:9200/ratings-with-customer-data/_doc" -H 'Content-Type: application/json' -d'{
          "RATING_ID": 79,
          "CHANNEL": "iOS",
          "STARS": 4,
          "MESSAGE": "Surprisingly good, maybe you are getting your mojo back at long last!",
          "ID": 1,
          "CLUB_STATUS": "bronze",
          "EMAIL": "rblaisdell0@rambler.ru",
          "FIRST_NAME": "Rica",
          "LAST_NAME": "Blaisdell",
          "EXTRACT_TS": 1528992287749
        }'
curl -XPOST "http://localhost:9200/unhappy_platinum_customers/_doc" -H 'Content-Type: application/json' -d'{
          "MESSAGE": "why is it so difficult to keep the bathrooms clean ?",
          "STARS": 1,
          "EXTRACT_TS": 1528992291449,
          "CLUB_STATUS": "platinum",
          "EMAIL": "rleheude5@reddit.com"
        }'
curl 'http://localhost:5601/api/saved_objects/index-pattern' -H 'kbn-version: 6.3.0' -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' --data-binary '{"attributes":{"title":"ratings-with-customer-data","timeFieldName":"EXTRACT_TS"}}' --compressed
curl 'http://localhost:5601/api/saved_objects/index-pattern' -H 'kbn-version: 6.3.0' -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' --data-binary '{"attributes":{"title":"unhappy_platinum_customers","timeFieldName":"EXTRACT_TS"}}' --compressed

