#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "testReplicator",
  "config": {
    "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
    "topic.whitelist": "_schemas",
    "topic.rename.format": "\${topic}.replica",
    "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "src.kafka.bootstrap.servers": "srcKafka1:10091",
    "dest.kafka.bootstrap.servers": "destKafka1:11091",
    "tasks.max": "1",
    "confluent.topic.replication.factor": "1",
    "schema.subject.translator.class": "io.confluent.connect.replicator.schemas.DefaultSubjectTranslator",
    "schema.registry.topic": "_schemas",
    "schema.registry.url": "http://destSchemaregistry:8086"
  }
}
EOF
)

RETCODE=1
while [ $RETCODE -ne 0 ]
do
  curl -f -X POST -H "${HEADER}" --data "${DATA}" http://connect:8083/connectors
  RETCODE=$?
  if [ $RETCODE -ne 0 ]
  then
    echo "Failed to submit replicator to Connect. This could be because the Connect worker is not yet started. Will retry in 10 seconds"
  fi
  #backoff
  sleep 10
done

