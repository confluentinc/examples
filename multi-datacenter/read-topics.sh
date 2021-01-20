#!/bin/bash

# Source Confluent Platform versions
source ../utils/config.env

# This script is purely to output some interesting data to help you understand the replication process

echo -e "\n-----dc1-----"
echo -e "\nlist topics:"
docker-compose exec broker-dc1 kafka-topics --list --bootstrap-server broker-dc1:29091
echo -e "\ntopic1:"
docker-compose exec schema-registry-dc1 kafka-avro-console-consumer --topic topic1 --bootstrap-server broker-dc1:29091 --property schema.registry.url=http://schema-registry-dc1:8081 --max-messages 10 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
echo -e "\ntopic2:"
docker-compose exec schema-registry-dc1 kafka-avro-console-consumer --topic topic2 --bootstrap-server broker-dc1:29091 --max-messages 10 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
echo -e "\n_schemas:"
docker-compose exec broker-dc1 kafka-console-consumer --topic _schemas --bootstrap-server broker-dc1:29091 --from-beginning --timeout-ms 5000
echo -e "\nprovenance info (cluster, topic, timestamp):"
docker-compose exec connect-dc1 bash -c 'JAR_P=$(ls /usr/share/java/kafka-connect-replicator/connect-replicator-*.jar) ; export CLASSPATH=${JAR_P} ; kafka-console-consumer --topic topic1 --bootstrap-server broker-dc1:29091 --max-messages 10 --formatter=io.confluent.connect.replicator.tools.ProvenanceHeaderFormatter'
echo -e "\ntimestamp info (group: topic-partition):"
docker-compose exec connect-dc1 bash -c 'JAR_T=$(ls /usr/share/java/kafka-connect-replicator/timestamp-interceptor-*.jar) ; export CLASSPATH=${JAR_T} ; kafka-console-consumer --topic __consumer_timestamps --bootstrap-server broker-dc1:29091 --property print.key=true --property key.deserializer=io.confluent.connect.replicator.offsets.GroupTopicPartitionDeserializer --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer --max-messages 2'
echo -e "\ncluster id:"
docker-compose exec broker-dc1 curl http://broker-dc1:8090/v1/metadata/id | jq -r ".id"

echo -e "\n-----dc2-----"
echo -e "\nlist topics:"
docker-compose exec broker-dc2 kafka-topics --list --bootstrap-server broker-dc2:29092
echo -e "\ntopic1:"
docker-compose exec schema-registry-dc1 kafka-avro-console-consumer --topic topic1 --bootstrap-server broker-dc2:29092 --property schema.registry.url=http://schema-registry-dc1:8081 --max-messages 10 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
echo -e "\ntopic2.replica:"
docker-compose exec schema-registry-dc1 kafka-avro-console-consumer --topic topic2.replica --bootstrap-server broker-dc2:29092 --max-messages 10 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
echo -e "\n_schemas:"
docker-compose exec broker-dc1 kafka-console-consumer --topic _schemas --bootstrap-server broker-dc2:29092 --from-beginning --timeout-ms 5000
echo -e "\nprovenance info (cluster, topic, timestamp):"
docker-compose exec connect-dc2 bash -c 'JAR_P=$(ls /usr/share/java/kafka-connect-replicator/connect-replicator-*.jar) ; export CLASSPATH=${JAR_P} ; kafka-console-consumer --topic topic1 --bootstrap-server broker-dc2:29092 --max-messages 10 --formatter=io.confluent.connect.replicator.tools.ProvenanceHeaderFormatter'
echo -e "\ntimestamp info (group: topic-partition):"
docker-compose exec connect-dc2 bash -c 'JAR_T=$(ls /usr/share/java/kafka-connect-replicator/timestamp-interceptor-*.jar) ; export CLASSPATH=${JAR_T} ; kafka-console-consumer --topic __consumer_timestamps --bootstrap-server broker-dc2:29092 --property print.key=true --property key.deserializer=io.confluent.connect.replicator.offsets.GroupTopicPartitionDeserializer --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer --max-messages 2'
echo -e "\ncluster id:"
docker-compose exec broker-dc2 curl http://broker-dc2:8090/v1/metadata/id | jq -r ".id"

echo -e "\n-----map-topics-clients-----"
./map_topics_clients.py
