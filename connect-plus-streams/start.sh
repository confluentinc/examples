#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 4.1 || exit 

./stop.sh

get_ksql_ui
confluent start

# Prep SQL table
TABLE_LOCATIONS=/usr/local/lib/table.locations
prep_sqltable

# Compile java
mvn compile

# --------------------------------------------------------------

PACKAGE="console-producer-java-consumer"
TOPIC="$PACKAGE-locations"
echo -e "\n========== $PACKAGE ============"

# Write the contents of the file TABLE_LOCATIONS to the Topic `consoleproducer`, where the id is the message key and the name and sale are the message value.
cat $TABLE_LOCATIONS | \
kafka-console-producer \
--broker-list localhost:9092 \
--topic $TOPIC \
--property parse.key=true \
--property key.separator='|'

# Run the Java consumer application
timeout 20s mvn exec:java -Dexec.mainClass=io.confluent.examples.connectandstreams.consoleproducer.StreamsIngest

show_topic $TOPIC

# --------------------------------------------------------------

PACKAGE="connect-producer-java-consumer-json"
TOPIC="$PACKAGE-locations"
echo -e "\n========== $PACKAGE ============"

# --------------------------------------------------------------

PACKAGE="connect-producer-java-consumer-generic-avro"
TOPIC="$PACKAGE-locations"
echo -e "\n========== $PACKAGE ============"

# --------------------------------------------------------------

PACKAGE="java-producer-java-consumer-specific-avro"
TOPIC="$PACKAGE-locations"
echo -e "\n========== $PACKAGE ============"
