#!/bin/bash

# Source library
. ../utils/helper.sh

if is_ce; then PROPERTIES=" propertiesFile=$CONFLUENT_HOME/etc/ksql/datagen.properties"; else PROPERTIES=""; fi
echo -e "\nStarting data generators…"
ksql-datagen -daemon quickstart=clickstream format=json topic=clickstream maxInterval=100 iterations=500000 $PROPERTIES &>/dev/null &
echo -e "…"
ksql-datagen quickstart=clickstream_codes format=json topic=clickstream_codes maxInterval=20 iterations=100 $PROPERTIES &>/dev/null &
echo -e "…"
ksql-datagen quickstart=clickstream_users format=json topic=clickstream_users maxInterval=10 iterations=1000 $PROPERTIES &>/dev/null &
sleep 5
echo -e "…done\n"
