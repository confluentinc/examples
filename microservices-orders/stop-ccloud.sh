#!/bin/bash

# Source library 
source ../utils/helper.sh
source ../utils/ccloud_library.sh

# Destroy Confluent Cloud resources
if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './start-ccloud.sh'. (Is it in stack-configs/ folder?) "
  exit 1
fi

docker-compose down -v
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
CONFIG_FILE=${DIR}/$1
../ccloud/ccloud-stack/ccloud_stack_destroy.sh $CONFIG_FILE

