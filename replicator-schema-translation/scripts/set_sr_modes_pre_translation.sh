#!/bin/bash

HEADER="Content-Type: application/json"

curl -X PUT -H "${HEADER}" --data '{"mode": "READONLY"}' http://srcSchemaregistry:8085/mode
curl -X PUT -H "${HEADER}" --data '{"mode": "IMPORT"}' http://destSchemaregistry:8086/mode

