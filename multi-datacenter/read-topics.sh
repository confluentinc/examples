#!/bin/bash

# This script is purely to output some interesting data to help you understand the replication process

echo -e "\n-----dc1-----"
echo -e "\nlist topics:"
docker-compose exec broker-dc1 kafka-topics --list --zookeeper zookeeper-dc1:2181
echo -e "\ntopic1:"
docker-compose exec schema-registry-dc1 kafka-avro-console-consumer --topic topic1 --bootstrap-server broker-dc1:29091 --property schema.registry.url=http://schema-registry-dc1:8081 --max-messages 10 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
echo -e "\ntopic2:"
docker-compose exec schema-registry-dc1 kafka-avro-console-consumer --topic topic2 --bootstrap-server broker-dc1:29091 --max-messages 10 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
echo -e "\n_schemas:"
docker-compose exec broker-dc1 kafka-console-consumer --topic _schemas --bootstrap-server broker-dc1:29091 --from-beginning --timeout-ms 5000
echo -e "\nprovenance info (cluster, topic, timestamp):"
docker-compose exec connect-dc1 bash -c "export CLASSPATH=/usr/share/java/kafka-connect-replicator/kafka-connect-replicator-5.3.1-SNAPSHOT.jar && kafka-console-consumer --topic topic1 --bootstrap-server broker-dc1:29091 --max-messages 10 --formatter=io.confluent.connect.replicator.tools.ProvenanceHeaderFormatter"
echo -e "\ntimestamp info (group: topic-partition):"
docker-compose exec connect-dc1 bash -c "export CLASSPATH=/usr/share/java/kafka-connect-replicator/kafka-connect-replicator-5.3.1-SNAPSHOT.jar && kafka-console-consumer --topic __consumer_timestamps --bootstrap-server broker-dc1:29091 --property print.key=true --property key.deserializer=io.confluent.connect.replicator.offsets.GroupTopicPartitionDeserializer --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer --max-messages 2"
echo -e "\ncluster id:"
docker-compose exec zookeeper-dc1 zookeeper-shell localhost:2181 get /cluster/id | grep version | grep id | jq -r .id

echo -e "\n-----dc2-----"
echo -e "\nlist topics:"
docker-compose exec broker-dc2 kafka-topics --list --zookeeper zookeeper-dc2:2182
echo -e "\ntopic1:"
docker-compose exec schema-registry-dc1 kafka-avro-console-consumer --topic topic1 --bootstrap-server broker-dc2:29092 --property schema.registry.url=http://schema-registry-dc1:8081 --max-messages 10 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
echo -e "\ntopic2.replica:"
docker-compose exec schema-registry-dc1 kafka-avro-console-consumer --topic topic2.replica --bootstrap-server broker-dc2:29092 --max-messages 10 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
echo -e "\n_schemas:"
docker-compose exec broker-dc1 kafka-console-consumer --topic _schemas --bootstrap-server broker-dc2:29092 --from-beginning --timeout-ms 5000
echo -e "\nprovenance info (cluster, topic, timestamp):"
docker-compose exec connect-dc2 bash -c "export CLASSPATH=/usr/share/java/kafka-connect-replicator/kafka-connect-replicator-5.3.1-SNAPSHOT.jar && kafka-console-consumer --topic topic1 --bootstrap-server broker-dc2:29092 --max-messages 10 --formatter=io.confluent.connect.replicator.tools.ProvenanceHeaderFormatter"
echo -e "\ntimestamp info (group: topic-partition):"
docker-compose exec connect-dc2 bash -c "export CLASSPATH=/usr/share/java/kafka-connect-replicator/kafka-connect-replicator-5.3.1-SNAPSHOT.jar && kafka-console-consumer --topic __consumer_timestamps --bootstrap-server broker-dc2:29092 --property print.key=true --property key.deserializer=io.confluent.connect.replicator.offsets.GroupTopicPartitionDeserializer --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer --max-messages 2"
echo -e "\ncluster id:"
docker-compose exec zookeeper-dc2 zookeeper-shell localhost:2182 get /cluster/id | grep version | grep id | jq -r .id

echo -e "\n-----map-topics-clients-----"
./map_topics_clients.py
