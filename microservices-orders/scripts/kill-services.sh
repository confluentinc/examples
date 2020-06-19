#!/bin/bash

while read -r -a pids;
do
  for i in "${pids[@]}"
  do
    kill -15 $i 2> /dev/null
  done
done < $1
