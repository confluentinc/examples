#!/bin/bash

zookeeper-shell $1 get /cluster/id
version=$(zookeeper-shell $1 get /cluster/id 2> /dev/null  | grep version)
echo $version
if [ $version ]; then
    exit 0
else
    exit 1
fi