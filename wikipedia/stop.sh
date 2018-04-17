#!/bin/bash

# Source library 
. ../utils/helper.sh

check_env || exit 1

jps | grep DataGen | awk '{print $1;}' | xargs kill -9
confluent destroy

# ps -ef | grep kibana | awk '{print $1;}' | xargs kill -9
# jps | grep Elasticsearch | awk '{print $1;}' | xargs kill -9
