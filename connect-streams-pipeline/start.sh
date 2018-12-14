#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_mvn || exit 1

./stop.sh

mvn clean compile

echo "auto.offset.reset=earliest" >> $CONFLUENT_HOME/etc/ksql/ksql-server.properties
confluent start

# Create the SQL table
TABLE_LOCATIONS=/usr/local/lib/table.locations
prep_sqltable_locations

# --------------------------------------------------------------

PACKAGE="jdbcgenericavro"
TOPIC="$PACKAGE-locations"
echo -e "\n========== $PACKAGE: Example 3b: JDBC source connector with GenericAvro -> Key:String(null) and Value:GenericAvro"
sleep 2

# Run source connector
confluent unload $PACKAGE &>/dev/null
confluent config $PACKAGE -d ./$PACKAGE-connector.properties &>/dev/null

# Run the Consumer to print the key as well as the value from the Topic
kafka-avro-console-consumer \
--property schema.registry=http://localhost:8081 \
--bootstrap-server localhost:9092 \
--from-beginning \
--topic $TOPIC \
--property print.key=true \
--max-messages 10

# Run the Java consumer application
timeout 10s mvn -q exec:java -Dexec.mainClass=io.confluent.examples.connectandstreams.$PACKAGE.StreamsIngest

# --------------------------------------------------------------

