#!/bin/bash

source ../utils/helper.sh

if [ ! -z "$KAFKA_STREAMS_BRANCH" ]; then
	CONFLUENT_RELEASE_TAG_OR_BRANCH=$KAFKA_STREAMS_BRANCH get_and_compile_kafka_streams_examples || exit 1;
else
	get_and_compile_kafka_streams_examples || exit 1;
fi;
