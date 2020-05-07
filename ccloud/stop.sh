#!/bin/bash

# Kill processes
confluent local destroy
jps | grep DataGen | awk '{print $1;}' | xargs kill -9
jps | grep KsqlServerMain | awk '{print $1;}' | xargs kill -9
jps | grep SchemaRegistry | awk '{print $1;}' | xargs kill -9
jps | grep ReplicatorApp | awk '{print $1;}' | xargs kill -9
jps | grep ControlCenter | awk '{print $1;}' | xargs kill -9
jps | grep ConnectDistributed | awk '{print $1;}' | xargs kill -9

if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './start.sh'. (Is it in stacks-config/ folder?) "
  exit 1
else
  ccloud-stack/ccloud_stack_destroy.sh $CONFIG_FILE
fi
