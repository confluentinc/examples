#!/bin/bash

# Kill processes
confluent local destroy
rm -fr /tmp/kafka-logs
rm -fr /tmp/control-center-logs
jps | grep DataGen | awk '{print $1;}' | xargs kill -9
jps | grep KsqlServerMain | awk '{print $1;}' | xargs kill -9
jps | grep SchemaRegistry | awk '{print $1;}' | xargs kill -9
jps | grep ReplicatorApp | awk '{print $1;}' | xargs kill -9
jps | grep ControlCenter | awk '{print $1;}' | xargs kill -9
jps | grep ConnectDistributed | awk '{print $1;}' | xargs kill -9

if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './start.sh'. (Is it in stack-configs/ folder?) "
  exit 1
else
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
  CONFIG_FILE=${DIR}/$1
  ccloud-stack/ccloud_stack_destroy.sh $CONFIG_FILE
fi
