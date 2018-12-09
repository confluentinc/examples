#!/bin/bash

topic_name=test1

ccloud topic create $topic_name

num_messages=10
for ((i=0;i<$num_messages;i++)); do
  echo "alice,{\"count\":${i}}" | confluent produce $topic_name --cloud --property parse.key=true --property key.separator=,
done

confluent consume $topic_name --cloud --property print.key=true --from-beginning --max-messages $num_messages
