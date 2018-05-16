![image](../images/confluent-logo-300-2.png)

[Prerequisites](#prerequisites)
[Overview](#overview)
[Quickstart](#quickstart)


# Prerequisites

* [Common demo prerequisites](https://github.com/confluentinc/quickstart-demos#prerequisites)
* [Confluent Platform 4.1](https://www.confluent.io/download/)

# Overview

## Objectives
1. Demonstrate various ways, with and without Kafka Connect, to get data into Kafka topics and then loaded into the Kafka Streams API `KStream`
2. Show some basic usage of the stream processing API

## Example 1: Kafka console producer -> `String`

Uses command line `kafka-console-producer` to produce `String` keys and `String` values to a Kafka topic.
Client application reads from the Kafka topic using `Serdes.String()` for both key and value.

### Notes

[KAFKA-2526](https://issues.apache.org/jira/browse/KAFKA-2526): one cannot use the `--key-serializer` argument in the `kafka-console-producer` to serialize the key as a `Long`. As a result, in this example the key is serialized as a `String`. As a workaround, you could write your own kafka.common.MessageReader (e.g. check out the default implementation of LineMessageReader) and then you can specify `--line-reader` argument in the `kafka-console-producer`.

## Example 2: JDBC source connector with Single Message Transformations -> JSON

Uses Kafka Connect JDBC source connector to produce JSON values, and inserts the key using single message transformations, also known as `SMTs`. This is helpful because by default JDBC source connector does not insert a key.
Client application reads from the Kafka topic using `Serdes.String()` for key and a custom JSON Serde for the value.

### Notes

[KAFKA-4714](https://github.com/apache/kafka/pull/2458): with this enhancement, the simple message transform will be able to cast the type of the key as `Long`. Until this is implemented, in this example the key is written as a `String`.

## Example 3: JDBC source connector with `GenericAvro` -> `GenericRecord`

Uses Kafka Connect JDBC source connector to produce Avro values, and null `String` keys, to a Kafka topic.
Client application reads from the Kafka topic using `GenericAvroSerde` for the value and then the `map` function to convert the stream of messages to have `Long` keys and custom class values.

### Notes

This example currently uses `GenericAvroSerde` and not `SpecificAvroSerde` for a specific reason. JDBC source connector currently doesn't set a namespace when it generates a schema name for the data it is producing to Kafka. For `SpecificAvroSerde`, the lack of namespace is a problem when trying to match reader and writer schema because Avro uses the writer schema name and namespace to create a classname and tries to load this class, but without a namespace, the class will not be found. A workaround will be available when [KAFKA-5164](https://issues.apache.org/jira/browse/KAFKA-5164) is fixed, using simple message transformation `SetSchemaMetadata` to add the namespace in the connector.

## Example 4: Java client producer with `SpecificAvro` -> Custom class

Uses Java client to produce `Long` keys and `SpecificAvro` values to a Kafka topic.
Client application reads from the Kafka topic using `Serdes.Long()` for key and `SpecificAvroSerde` for the value.

## Stream processing

All examples in this repo demonstrate the Kafka Streams API methods `count` and `reduce`.

### Notes

[KAFKA-5245](https://issues.apache.org/jira/browse/KAFKA-5245): one needs to provide the Serdes twice, (1) when calling `KStreamBuilder#stream()` and (2) when calling `KStream#groupByKey()`

[PR-531](https://github.com/confluentinc/schema-registry/pull/531): Confluent distribution provides packages for `GenericAvroSerde` and `SpecificAvroSerde`

[KAFKA-2378](https://issues.apache.org/jira/browse/KAFKA-2378): adds APIs to be able to embed Kafka Connect into client applications

# Quickstart

## Prerequisites

1. Use the Confluent CLI to start a Kafka cluster on your localhost. It will spin up services including one Kafka broker, ZooKeeper, Kafka Connect, Confluent Schema Registry.

```shell
confluent start
```

2. By default the `timeout` command is available on most Linux distributions but not Mac OS. This `timeout` command is used by the bash scripts to terminate consumer processes after a period of time. To install it on a Mac:

```shell
# Install coreutils
brew install coreutils

# Add a "gnubin" directory to your PATH
PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
```

3. **NOTE:** you may need to edit the file paths referenced in the bash scripts in the `scripts/` directory, particularly if you installed Confluent Platform via ZIP or TAR or are on Mac.

## Build the apps

Compile from the pom.xml file. This also generate sources to create the `avro.model.Location` Java code

```shell
mvn clean package
```

## Run the Examples

There are multiple examples of data flow as described above. Each example has a corresponding bash script in the `scripts/` directory, and the Java package name is built into the bash script name. The bash script does several things:
1. Copies `files/table.locations` to `/usr/local/lib/table.locations`
2. If the example uses the JDBC connector, creates a table called `locations` in a local sqlite database.
3. If the example uses the JDBC connector, starts Kafka Connect in standalone mode on the local machine
3. Produces data to a Kafka topic (method differs example to example)
4. Runs `StreamsIngest` class unique to each example to read data from the Kafka topic and do some simple streams processing

```shell
# Example 1: Kafka console producer -> `String`
./scripts/run-consoleproducer.sh

# Example 2: JDBC source connector with Single Message Transformations -> JSON
./scripts/run-jdbcjson.sh

# Example 3: JDBC source connector with `GenericAvro` -> `GenericRecord`
./scripts/run-jdbcgenericavro.sh

# Example 4: Java client producer with `SpecificAvro` -> custom class
./scripts/run-javaproducer.sh
```

## Overrides

Assumptions:
* Broker is `localhost:9092`
* Confluent Schema Registry is `http://localhost:8081`
* table.locations is copied to `/usr/local/lib/table.locations`
* sqlite3 database is created at `/usr/local/lib/sqlite3`

To override any of the above values, you will need to make appropriate changes in the following places:
* `scripts/`: bash scripts (file path, sqlite3 database path, ZooKeeper address, Java arguments)
* `files/`: properties files for Kafka Connect

## Original Dataset

Dataset is `files/table.locations`

```
1|Raleigh|300
2|Dusseldorf|100
1|Raleigh|600
3|Moscow|800
4|Sydney|200
2|Dusseldorf|400
5|Chennai|400
3|Moscow|100
3|Moscow|200
1|Raleigh|700
```
