![image](../images/confluent-logo-300-2.png)

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Description](#description)
- [Quickstart](#quickstart)


# Overview

1. Demonstrate various ways, with and without Kafka Connect, to get data into Kafka topics and then loaded for use by the Kafka Streams API `KStream`
2. Show some basic usage of the stream processing API

For more information, please read [this blogpost](https://www.confluent.io/blog/building-real-time-streaming-etl-pipeline-20-minutes/).

# Prerequisites

* [Common demo prerequisites](https://github.com/confluentinc/examples#prerequisites)
* [Confluent Platform 5.0](https://www.confluent.io/download/)
* Maven command `mvn` to compile Java code
* By default the `timeout` command is available on most Linux distributions but not Mac OS. This `timeout` command is used by the bash scripts to terminate consumer processes after a period of time. To install it on a Mac:

```shell
# Install coreutils
brew install coreutils

# Add a "gnubin" directory to your PATH
PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
```

# Description

## Example 1: Kafka console producer -> Key:String and Value:String

* Command line `kafka-console-producer` produces `String` keys and `String` values to a Kafka topic.
* [Client application](src/main/java/io/confluent/examples/connectandstreams/consoleproducer/StreamsIngest.java) reads from the Kafka topic using `Serdes.String()` for both key and value.

![image](images/example_1.jpg)

### Notes

[KAFKA-2526](https://issues.apache.org/jira/browse/KAFKA-2526): one cannot use the `--key-serializer` argument in the `kafka-console-producer` to serialize the key as a `Long`. As a result, in this example the key is serialized as a `String`. As a workaround, you could write your own kafka.common.MessageReader (e.g. check out the default implementation of LineMessageReader) and then you can specify `--line-reader` argument in the `kafka-console-producer`.

## Example 2: JDBC source connector with Single Message Transformations -> Key:Long and Value:JSON

* [Kafka Connect JDBC source connector](jdbcjson-connector.properties) produces JSON values, and inserts the key using single message transformations, also known as `SMTs`. This is helpful because by default JDBC source connector does not insert a key.
* [Client application](src/main/java/io/confluent/examples/connectandstreams/jdbcjson/StreamsIngest.java) reads from the Kafka topic using `Serdes.String()` for key and a custom JSON Serde for the value.

![image](images/blog_connect_streams_diag.jpg)

### Notes

This example uses a few SMTs including one to cast the key to an `int64`. The key uses the `org.apache.kafka.connect.converters.LongConverter` provided by [KAFKA-6913](https://issues.apache.org/jira/browse/KAFKA-6913).

## Example 3a: JDBC source connector with SpecificAvro -> Key:String(null) and Value:SpecificAvro

* [Kafka Connect JDBC source connector](jdbcspecificavro-connector.properties) produces Avro values, and null `String` keys, to a Kafka topic.
* [Client application](src/main/java/io/confluent/examples/connectandstreams/jdbcspecificavro/StreamsIngest.java) reads from the Kafka topic using `SpecificAvroSerde` for the value and then the `map` function to convert the stream of messages to have `Long` keys and custom class values.

![image](images/blog_connect_streams_diag.jpg)

### Notes

This example uses a simple message transformation `SetSchemaMetadata` with code that has a fix for [KAFKA-5164](https://issues.apache.org/jira/browse/KAFKA-5164), allowing the connector to set the namespace in the schema. If you do not have the fix for [KAFKA-5164](https://issues.apache.org/jira/browse/KAFKA-5164), see Example 3b that uses `GenericAvro` instead of `SpecificAvro`.

## Example 3b: JDBC source connector with GenericAvro -> Key:String(null) and Value:GenericAvro

* [Kafka Connect JDBC source connector](jdbcgenericavro-connector.properties) produces Avro values, and null `String` keys, to a Kafka topic.
* [Client application](src/main/java/io/confluent/examples/connectandstreams/jdbcgenericavro/StreamsIngest.java) reads from the Kafka topic using `GenericAvroSerde` for the value and then the `map` function to convert the stream of messages to have `Long` keys and custom class values.

![image](images/blog_connect_streams_diag.jpg)

### Notes

This example currently uses `GenericAvroSerde` and not `SpecificAvroSerde` for a specific reason. JDBC source connector currently doesn't set a namespace when it generates a schema name for the data it is producing to Kafka. For `SpecificAvroSerde`, the lack of namespace is a problem when trying to match reader and writer schema because Avro uses the writer schema name and namespace to create a classname and tries to load this class, but without a namespace, the class will not be found.

## Example 4: Java client producer with SpecificAvro -> Key:Long and Value:SpecificAvro

* [Java client](src/main/java/io/confluent/examples/connectandstreams/javaproducer/Driver.java) produces `Long` keys and `SpecificAvro` values to a Kafka topic.
* [Client application](src/main/java/io/confluent/examples/connectandstreams/javaproducer/StreamsIngest.java) reads from the Kafka topic using `Serdes.Long()` for key and `SpecificAvroSerde` for the value.

## Example 5: JDBC source connector with Avro to KSQL -> Key:Long and Value:Avro

* [Kafka Connect JDBC source connector](jdbcavroksql-connector.properties) produces Avro values, and null keys, to a Kafka topic.
* [KSQL](jdbcavroksql.commands) reads from the Kafka topic and then uses `PARTITION BY` to create a new stream of messages with `BIGINT` keys.

## Stream processing

All examples in this repo demonstrate the Kafka Streams API methods `count` and `reduce`.

### Notes

[KAFKA-5245](https://issues.apache.org/jira/browse/KAFKA-5245): one needs to provide the Serdes twice, (1) when calling `StreamsBuilder#stream()` and (2) when calling `KStream#groupByKey()`

[PR-531](https://github.com/confluentinc/schema-registry/pull/531): Confluent distribution provides packages for `GenericAvroSerde` and `SpecificAvroSerde`

[KAFKA-2378](https://issues.apache.org/jira/browse/KAFKA-2378): adds APIs to be able to embed Kafka Connect into client applications

# Quickstart

# What Should I see?

After you run `./start.sh`:

* You should see each of the examples run end-to-end
* If you are running Confluent Platform, open your browser and navigate to the Control Center web interface Management -> Kafka Connect tab at http://localhost:9021/management/connect to see the two deployed connectors
* Beyond that, the real value of this demo is to see the provided configurations and client code


## Original Dataset

[Dataset](../utils/table.locations)

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

![image](images/blog_stream.jpg)

## Expected Results

### Count

```
1|Raleigh|3
2|Dusseldorf|2
3|Moscow|3
4|Sydney|1
5|Chennai|1
```

![image](images/blog_count.jpg)

### Sum

```
1|Raleigh|1600
2|Dusseldorf|500
3|Moscow|1100
4|Sydney|200
5|Chennai|400
```

![image](images/blog_sum.jpg)
