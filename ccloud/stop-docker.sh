#!/bin/bash

docker-compose down -v

if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './start-docker.sh'. (Is it in stack-configs/ folder?) "
  exit 1
else
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
  CONFIG_FILE=${DIR}/$1
  ccloud-stack/ccloud_stack_destroy.sh $CONFIG_FILE
fi
