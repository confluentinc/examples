#!/bin/bash

# Source library 
source ../utils/helper.sh

check_env || exit 1

jps | grep Launcher | awk '{print $1;}' | xargs kill -9
docker compose down
rm -fr /tmp/kafka-streams
