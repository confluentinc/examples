#!/bin/bash

# Source library 
. ../utils/helper.sh

check_env || exit 1

jps | grep Launcher | awk '{print $1;}' | xargs kill -9
confluent local destroy

# This is used in the services
rm -fr /tmp/kafka-streams
