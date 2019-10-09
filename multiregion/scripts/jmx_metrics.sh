#!/bin/bash

echo -e "\n\n==> Monitor CaughtUpReplicas \n"

for topic in single-region multi-region-sync multi-region-async
do
  BW1=$(docker-compose exec broker-west-1 kafka-run-class kafka.tools.JmxTool --jmx-url service:jmx:rmi:///jndi/rmi://localhost:8091/jmxrmi --object-name kafka.cluster:type=Partition,name=CaughtUpReplicas,topic=$topic,partition=0 --one-time true | tail -n 1 | awk -F, '{print $2;}' | head -c 1)
  BW2=$(docker-compose exec broker-west-2 kafka-run-class kafka.tools.JmxTool --jmx-url service:jmx:rmi:///jndi/rmi://localhost:8092/jmxrmi --object-name kafka.cluster:type=Partition,name=CaughtUpReplicas,topic=$topic,partition=0 --one-time true | tail -n 1 | awk -F, '{print $2;}' | head -c 1)
  BE1=$(docker-compose exec broker-east-3 kafka-run-class kafka.tools.JmxTool --jmx-url service:jmx:rmi:///jndi/rmi://localhost:8093/jmxrmi --object-name kafka.cluster:type=Partition,name=CaughtUpReplicas,topic=$topic,partition=0 --one-time true | tail -n 1 | awk -F, '{print $2;}' | head -c 1)
  BE2=$(docker-compose exec broker-east-4 kafka-run-class kafka.tools.JmxTool --jmx-url service:jmx:rmi:///jndi/rmi://localhost:8094/jmxrmi --object-name kafka.cluster:type=Partition,name=CaughtUpReplicas,topic=$topic,partition=0 --one-time true | tail -n 1 | awk -F, '{print $2;}' | head -c 1)
  REPLICAS=$((BW1 + BW2 + BW3 + BW4))
  echo "$topic: $REPLICAS"
done

echo -e "\n\n==> Monitor InSyncReplicasCount \n"

for topic in single-region multi-region-sync multi-region-async
do
  BW1=$(docker-compose exec broker-west-1 kafka-run-class kafka.tools.JmxTool --jmx-url service:jmx:rmi:///jndi/rmi://localhost:8091/jmxrmi --object-name kafka.cluster:type=Partition,name=InSyncReplicasCount,topic=$topic,partition=0 --one-time true | tail -n 1 | awk -F, '{print $2;}' | head -c 1)
  BW2=$(docker-compose exec broker-west-2 kafka-run-class kafka.tools.JmxTool --jmx-url service:jmx:rmi:///jndi/rmi://localhost:8092/jmxrmi --object-name kafka.cluster:type=Partition,name=InSyncReplicasCount,topic=$topic,partition=0 --one-time true | tail -n 1 | awk -F, '{print $2;}' | head -c 1)
  BE1=$(docker-compose exec broker-east-3 kafka-run-class kafka.tools.JmxTool --jmx-url service:jmx:rmi:///jndi/rmi://localhost:8093/jmxrmi --object-name kafka.cluster:type=Partition,name=InSyncReplicasCount,topic=$topic,partition=0 --one-time true | tail -n 1 | awk -F, '{print $2;}' | head -c 1)
  BE2=$(docker-compose exec broker-east-4 kafka-run-class kafka.tools.JmxTool --jmx-url service:jmx:rmi:///jndi/rmi://localhost:8094/jmxrmi --object-name kafka.cluster:type=Partition,name=InSyncReplicasCount,topic=$topic,partition=0 --one-time true | tail -n 1 | awk -F, '{print $2;}' | head -c 1)
  REPLICAS=$((BW1 + BW2 + BW3 + BW4))
  echo "$topic: $REPLICAS"
done
