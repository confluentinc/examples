#!/bin/bash

# Source library 
. ../utils/helper.sh

check_env || exit 1
check_ccloud || exit

topics=$(ccloud topic list)

for topic in $topics
do
  if [[ ${topic:0:10} == '_confluent' ]]; then
    ccloud topic delete $topic
  fi
done

topics_to_delete="_schemas connect-configs connect-status connect-offsets"
for topic in $topics_to_delete
do
  echo $topics | grep $topic &>/dev/null
  if [[ $? == 0 ]]; then
    ccloud topic delete $topic
  fi
done
