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
    "src.kafka.bootstrap.servers": "srcKafka1:10091,srcKafka2:10092,srcKafka3:10093",
    "dest.kafka.bootstrap.servers": "destKafka1:11091,destKafka2:11092,destKafka3:11093",
    "tasks.max": "1",
    "dest.kafka.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"connect\" password=\"connect-secret\";",
    "dest.kafka.sasl.mechanism":"PLAIN",
    "dest.kafka.security.protocol":"SASL_PLAINTEXT"
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

