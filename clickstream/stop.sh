#!/bin/bash

# Source library 
. ../utils/helper.sh

check_env || exit 1

jps | grep DataGen | awk '{print $1;}' | xargs kill -9
confluent destroy

# jps | grep Elasticsearch | awk '{print $1;}' | xargs kill -9
