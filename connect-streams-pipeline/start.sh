#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_running_cp 4.1 || exit 

./stop.sh

# Compile java client code and copy custom LongConverter jar
mvn -q compile
(cd target/classes && jar cvf $CONFLUENT_HOME/share/java/kafka-connect-jdbc/LongConverter.jar io/confluent/examples/connectandstreams/utils/LongConverter.class)
jar cvf $CONFLUENT_HOME/share/java/kafka-connect-jdbc/LongConverter.jar ./target/classes/io/confluent/examples/connectandstreams/utils/LongConverter.class 

get_ksql_ui
confluent start

# Create the SQL table
TABLE_LOCATIONS=/usr/local/lib/table.locations
prep_sqltable

# --------------------------------------------------------------

PACKAGE="consoleproducer"
TOPIC="$PACKAGE-locations"
echo -e "\n========== $PACKAGE: Example 1: Kafka console producer -> Key:String and Value:String"
sleep 2

# Write the contents of the file TABLE_LOCATIONS to a Topic, where the id is the message key and the name and sale are the message value.
cat $TABLE_LOCATIONS | \
kafka-console-producer \
--broker-list localhost:9092 \
--topic $TOPIC \
--property parse.key=true \
--property key.separator='|' &>/dev/null

# Run the Java consumer application
timeout 5s mvn -q exec:java -Dexec.mainClass=io.confluent.examples.connectandstreams.$PACKAGE.StreamsIngest

# Run the Consumer to print the key as well as the value from the Topic
print_topic $TOPIC

# --------------------------------------------------------------

PACKAGE="jdbcjson"
TOPIC="$PACKAGE-locations"
echo -e "\n========== $PACKAGE: Example 2: JDBC source connector with Single Message Transformations -> Key:String and Value:JSON"
sleep 2

# Run source connector
confluent unload $PACKAGE &>/dev/null
confluent config $PACKAGE -d ./$PACKAGE-connector.properties &>/dev/null

# Run the Java consumer application
timeout 10s mvn -q exec:java -Dexec.mainClass=io.confluent.examples.connectandstreams.$PACKAGE.StreamsIngest

# Run the Consumer to print the key as well as the value from the Topic
print_topic $TOPIC

# --------------------------------------------------------------

PACKAGE="jdbcgenericavro"
TOPIC="$PACKAGE-locations"
echo -e "\n========== $PACKAGE: Example 3: JDBC source connector with GenericAvro -> Key:String(null) and Value:GenericAvro"
sleep 2

# Run source connector
confluent unload $PACKAGE &>/dev/null
confluent config $PACKAGE -d ./$PACKAGE-connector.properties &>/dev/null

# Run the Java consumer application
timeout 10s mvn -q exec:java -Dexec.mainClass=io.confluent.examples.connectandstreams.$PACKAGE.StreamsIngest

# Run the Consumer to print the key as well as the value from the Topic
print_topic $TOPIC

# --------------------------------------------------------------

PACKAGE="javaproducer"
TOPIC="$PACKAGE-locations"
echo -e "\n========== $PACKAGE: Example 4: Java client producer with SpecificAvro -> Key:Long and Value:SpecificAvro"
sleep 2

# Producer
timeout 10s mvn -q exec:java -Dexec.mainClass=io.confluent.examples.connectandstreams.$PACKAGE.Driver -Dexec.args="localhost:9092 http://localhost:8081 /usr/local/lib/table.locations"

# Consumer
timeout 10s mvn -q exec:java -Dexec.mainClass=io.confluent.examples.connectandstreams.$PACKAGE.StreamsIngest -Dexec.args="localhost:9092 http://localhost:8081"

curl -X GET http://localhost:8081/subjects/$TOPIC-value/versions/1

# Run the Consumer to print the key as well as the value from the Topic
print_topic $TOPIC
