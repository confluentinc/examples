#!/bin/bash

if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './start-docker.sh'. (Is it in stacks-config/ folder?) "
  exit 1
else
  ccloud-stack/ccloud_stack_destroy.sh $CONFIG_FILE
fi

docker-compose down -v
