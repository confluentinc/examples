#!/bin/bash

# Source library 
source ../utils/helper.sh

check_env || exit 1

jps | grep DataGen | awk '{print $1;}' | xargs kill -9
confluent local destroy
