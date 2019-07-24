#!/bin/bash

TAG=$1
`aws ecr get-login --no-include-email --region us-west-2`

if [ -z "$2" ]; then
    PREFIX=368821881613.dkr.ecr.us-west-2.amazonaws.com/confluentinc
else
    PREFIX=$2
fi

declare -a NAMES=("cp-zookeeper" "cp-enterprise-kafka" "cp-schema-registry" \
                  "cp-enterprise-control-center" "cp-enterprise-replicator" \
                  "cp-ksql-server" "cp-ksql-cli" "cp-kafka-connect" "cp-kafka-rest" \
                  "kafka-streams-examples" "ksql-examples" "cp-server" "cp-server-connect")
for NAME in "${NAMES[@]}"
do
    docker image pull ${PREFIX}/${NAME}:${TAG}
    docker image tag ${PREFIX}/${NAME}:${TAG} confluentinc/${NAME}:sanity
done
