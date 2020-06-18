#!/bin/bash

# Source library 
source ../utils/helper.sh

check_env || exit 1

./scripts/kill-services.sh .microservices.pids
rm .microservices.pids
confluent local destroy 2> /dev/null

# This is used in the services
rm -fr /tmp/kafka-streams
