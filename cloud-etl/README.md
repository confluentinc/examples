![image](../images/confluent-logo-300-2.png)

# Overview

This demo showcases a cloud ETL leveraging all fully-managed services on [Confluent Cloud](https://confluent.cloud?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cloud-etl)
A source connector reads data from an AWS Kinesis stream into Confluent Cloud, a Confluent KSQL application processes that data, and then a sink connector writes the output data into cloud storage in the provider of your choice.

![image](images/topology.jpg)

This enables you to:

* Build business applications on a full event streaming platform
* Span multiple cloud providers (AWS, GCP, Azure) and on-prem datacenters
* Use Kafka to aggregate data in single source of truth
* Harness the power of [KSQL](https://www.confluent.io/product/ksql/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cloud-etl)

# End-to-end Streaming ETL

This demo showcases an entire end-to-end cloud ETL deployment, built for 100% cloud services:

* Kinesis source connector: reads from a Kinesis stream and writes the data to a Kafka topic in Confluent Cloud
* KSQL: streaming SQL engine that enables real-time data processing against Kafka
* GCS or S3 sink connector: pushes data from Kafka topics to cloud storage

| Component                  | Consumes From              | Produces To             |
|----------------------------|----------------------------|-------------------------|
| Kinesis source connector   | Kinesis stream `demo-logs` | Kafka topic `eventLogs` |
| KSQL                       | `eventLogs`                | KSQL streams and tables ([ksql.commands](ksql.commands)) |
| GCS/S3/Blob sink connector | KSQL tables `COUNT_PER_SOURCE`, `SUM_PER_SOURCE` | GCS/S3/Blob         |

# Warning

This demo uses real cloud resources, including that of Confluent Cloud, Amazon Kinesis, and one of the cloud storage providers.
To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done running it.

# Prerequisites

## Cloud services

* [Confluent Cloud cluster](https://confluent.cloud?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cloud-etl): for development only. Do not use a production cluster.
* [Confluent Cloud KSQL](https://docs.confluent.io/current/quickstart/cloud-quickstart/ksql.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cloud-etl) provisioned in your Confluent Cloud
* [Confluent Platform 5.4](https://www.confluent.io/download/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cloud-etl): for more advanced Confluent CLI functionality (optional)
* AWS or GCP or Azure access

## Local install

* [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html#ccloud-install-cli?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud) v0.234.0 or later
* AWS S3: `aws` CLI, properly initialized with your credentials
* GCP GCS: `gsutils` CLI, properly initialized with your credentials
* Azure Blob: `az` CLI, properly initialized with your credentials
* `jq`
* `curl`

# Run the Demo

## Setup

1. Initialize a properties file at `$HOME/.ccloud/config` with the following configuration parameters for your Confluent Cloud cluster:

```shell
$ cat $HOME/.ccloud/config
bootstrap.servers=<BROKER ENDPOINT>
ssl.endpoint.identification.algorithm=https
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
schema.registry.url=https://<SR ENDPOINT>
schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
basic.auth.credentials.source=USER_INFO
ksql.endpoint=https://<KSQL ENDPOINT>
ksql.basic.auth.user.info=<KSQL API KEY>:<SR KSQL SECRET>
```

To get the right values for the endpoints in the file above, find them either via the Confluent Cloud UI or Confluent Cloud CLI commands.
If you have multiple Confluent Cloud clusters, make sure to use the one with the associated KSQL cluster.

```
# Login
ccloud login --url https://confluent.cloud

# BROKER ENDPOINT
ccloud kafka cluster list
ccloud kafka cluster use
ccloud kafka cluster describe

# SR ENDPOINT
ccloud schema-registry cluster describe

# KSQL ENDPOINT
ccloud ksql app list
```

2. Modify the demo configuration file at `config/demo.cfg` for your particular cloud storage provider and other demo parameters.

3. Log into Confluent Cloud with the command 'ccloud login', and use your Confluent Cloud username and password.

```
ccloud login --url https://confluent.cloud
```

## Run

4. Run the demo. It takes approximately 7 minutes to run.

```bash
$ ./start.sh
```

## Validate

5. From the Confluent Cloud UI, view the Flow:

![image](images/flow.png)

6. View all the data from Kinesis, Kafka, and cloud storage after running the demo:

```bash
$ ./read-data.sh
```

Sample output:

```
Data from Kinesis stream demo-logs --limit 10:
{"eventSourceIP":"192.168.1.1","eventAction":"Upload","result":"Pass","eventDuration":3}
{"eventSourceIP":"192.168.1.1","eventAction":"Create","result":"Pass","eventDuration":2}
{"eventSourceIP":"192.168.1.1","eventAction":"Delete","result":"Fail","eventDuration":5}
{"eventSourceIP":"192.168.1.2","eventAction":"Upload","result":"Pass","eventDuration":1}
{"eventSourceIP":"192.168.1.2","eventAction":"Create","result":"Pass","eventDuration":3}
{"eventSourceIP":"192.168.1.1","eventAction":"Upload","result":"Pass","eventDuration":3}
{"eventSourceIP":"192.168.1.1","eventAction":"Create","result":"Pass","eventDuration":2}
{"eventSourceIP":"192.168.1.1","eventAction":"Delete","result":"Fail","eventDuration":5}
{"eventSourceIP":"192.168.1.2","eventAction":"Upload","result":"Pass","eventDuration":1}
{"eventSourceIP":"192.168.1.2","eventAction":"Create","result":"Pass","eventDuration":3}

Data from Kafka topic eventLogs:
confluent local consume eventLogs -- --cloud --from-beginning --property print.key=true --max-messages 10
5	{"eventSourceIP":"192.168.1.5","eventAction":"Upload","result":"Pass","eventDuration":4}
5	{"eventSourceIP":"192.168.1.5","eventAction":"Create","result":"Pass","eventDuration":1}
5	{"eventSourceIP":"192.168.1.5","eventAction":"Delete","result":"Fail","eventDuration":1}
5	{"eventSourceIP":"192.168.1.5","eventAction":"Upload","result":"Pass","eventDuration":4}
5	{"eventSourceIP":"192.168.1.5","eventAction":"Create","result":"Pass","eventDuration":1}
5	{"eventSourceIP":"192.168.1.5","eventAction":"Delete","result":"Fail","eventDuration":1}
5	{"eventSourceIP":"192.168.1.5","eventAction":"Upload","result":"Pass","eventDuration":4}
5	{"eventSourceIP":"192.168.1.5","eventAction":"Create","result":"Pass","eventDuration":1}
5	{"eventSourceIP":"192.168.1.5","eventAction":"Delete","result":"Fail","eventDuration":1}
5	{"eventSourceIP":"192.168.1.5","eventAction":"Upload","result":"Pass","eventDuration":4}

Data from Kafka topic COUNT_PER_SOURCE:
confluent local consume COUNT_PER_SOURCE -- --cloud --from-beginning --property print.key=true --max-messages 10
192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":1}
192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":2}
192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":3}
192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":4}
192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":5}
192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":6}
192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":7}
192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":8}
192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":9}
192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":10}

Data from Kafka topic SUM_PER_SOURCE:
confluent local consume SUM_PER_SOURCE -- --cloud --from-beginning --property print.key=true --value-format avro --property basic.auth.credentials.source=USER_INFO --property schema.registry.basic.auth.user.info=WZVZVUOIOYEITVDY:680fJRxdHGIkK3dVisMEM5nl6b+d74xvPgRhlUx4i/OQpT3B+Zlz2qtVEE01wKto --property schema.registry.url=https://psrc-lz3xz.us-central1.gcp.confluent.cloud --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --max-messages 10
192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":1}}
192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":4}}
192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":5}}
192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":8}}
192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":11}}
192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":12}}
192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":15}}
192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":16}}
192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":19}}
192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":22}}

Objects in Cloud storage az:

topics/COUNT_PER_SOURCE/year=2020/month=02/day=11/hour=18/COUNT_PER_SOURCE+1+0000000000.bin
topics/COUNT_PER_SOURCE/year=2020/month=02/day=11/hour=18/COUNT_PER_SOURCE+1+0000001000.bin
topics/COUNT_PER_SOURCE/year=2020/month=02/day=11/hour=18/COUNT_PER_SOURCE+1+0000002000.bin
topics/COUNT_PER_SOURCE/year=2020/month=02/day=11/hour=18/COUNT_PER_SOURCE+1+0000003000.bin
topics/COUNT_PER_SOURCE/year=2020/month=02/day=11/hour=18/COUNT_PER_SOURCE+1+0000004000.bin
topics/COUNT_PER_SOURCE/year=2020/month=02/day=11/hour=18/COUNT_PER_SOURCE+3+0000000000.bin
topics/COUNT_PER_SOURCE/year=2020/month=02/day=11/hour=18/COUNT_PER_SOURCE+3+0000001000.bin
topics/COUNT_PER_SOURCE/year=2020/month=02/day=11/hour=18/COUNT_PER_SOURCE+3+0000002000.bin
topics/COUNT_PER_SOURCE/year=2020/month=02/day=11/hour=18/COUNT_PER_SOURCE+3+0000003000.bin
topics/COUNT_PER_SOURCE/year=2020/month=02/day=11/hour=18/COUNT_PER_SOURCE+3+0000004000.bin
```

## Stop

7. Stop the demo and clean up all the resources, delete Kafka topics, delete the fully-managed connectors, delete the data in the cloud storage:

```bash
$ ./stop.sh
```
