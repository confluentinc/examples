#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "testReplicator",
  "config": {
    "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
    "topic.whitelist": "testTopic",
    "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "src.kafka.bootstrap.servers": "srcKafka1:10091",
    "dest.kafka.bootstrap.servers": "destKafka1:11091",
    "tasks.max": "1",
    "src.kafka.ssl.truststore.location":"/etc/kafka/secrets/kafka.connect.truststore.jks",
    "src.kafka.ssl.truststore.password":"confluent",
    "src.kafka.ssl.keystore.location":"/etc/kafka/secrets/kafka.connect.keystore.jks",
    "src.kafka.ssl.keystore.password":"confluent",
    "src.kafka.ssl.key.password":"confluent",
    "src.kafka.security.protocol":"SSL",
    "confluent.topic.replication.factor": "1"
  }
}
EOF
)

RETCODE=1
while [ $RETCODE -ne 0 ]
do
  curl -f -X POST -H "${HEADER}" --data "${DATA}" http://connect:8083/connectors
  RETCODE=$?
done

