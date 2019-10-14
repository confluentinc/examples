#!/bin/bash

HEADER="Content-Type: application/json"

curl -X PUT -H "${HEADER}" --data '{"mode": "READWRITE"}' http://srcSchemaregistry:8085/mode
curl -X PUT -H "${HEADER}" --data '{"mode": "READWRITE"}' http://destSchemaregistry:8086/mode

