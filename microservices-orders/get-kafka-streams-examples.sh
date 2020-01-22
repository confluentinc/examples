#!/bin/bash

# Source Confluent Platform versions
. ../utils/config.env

# Compile java client code
[[ -d "kafka-streams-examples" ]] || git clone https://github.com/confluentinc/kafka-streams-examples.git
(cd kafka-streams-examples && git fetch && git checkout ${GIT_BRANCH} && git pull && mvn clean compile -DskipTests package)
if [[ $? != 0 ]]; then
  echo "ERROR: There seems to be a BUILD FAILURE error? Please troubleshoot"
  exit 1
else
  exit 0
fi
