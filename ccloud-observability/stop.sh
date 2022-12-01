#!/bin/bash

if [ -z "$METRICS_API_KEY" ]; then
  echo "ERROR: Must export parameter METRICS_API_KEY before running this script to destroy the API key created for metrics."
  exit 1
fi

if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './start.sh'. (Is it in stack-configs/ folder?) "
  exit 1
else
  confluent api-key delete $METRICS_API_KEY
  docker-compose down -v
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
  CONFIG_FILE=${DIR}/$1
  ../ccloud/ccloud-stack/ccloud_stack_destroy.sh $CONFIG_FILE
fi
