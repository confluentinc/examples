#!/bin/bash

HEADER="Content-Type: application/json"

echo -e "\nSetting srcSchemaregistry to READONLY mode:"
curl -X PUT -H "${HEADER}" --data '{"mode": "READONLY"}' http://srcSchemaregistry:8085/mode

echo -e "\nSetting destSchemaregistry to IMPORT mode:"
curl -X PUT -H "${HEADER}" --data '{"mode": "IMPORT"}' http://destSchemaregistry:8086/mode
