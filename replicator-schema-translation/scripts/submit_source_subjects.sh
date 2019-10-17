#!/bin/bash

HEADER="Content-Type: application/vnd.schemaregistry.v1+json"

RETCODE=1
while [ $RETCODE -ne 0 ]
do
  curl -f -X POST -H "${HEADER}" --data '{"schema": "{\"type\": \"string\"}"}' http://srcSchemaregistry:8085/subjects/testTopic-value/versions
  RETCODE=$?
done

