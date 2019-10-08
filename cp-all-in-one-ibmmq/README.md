![image](../images/confluent-logo-300-2.png)

# Overview

This [docker-compose.yml](docker-compose.yml) includes all of the Confluent Platform components and shows how you can configure them to interoperate.
For an example of how to use this Docker setup, refer to the Confluent Platform quickstart: https://docs.confluent.io/current/quickstart/index.html

# IBM MQ demo

```bash
make build

make cluster

# wait a minute

make topic

make connect

# wait a minute
# goto https://localhost:9443/ibmmq/console/

make consumer

# show AVRO message appear in consumer

# Show AVRO schema in C3 ibmmq topic http://localhost:9021/clusters/cdDGC2cKQhSx3fBE1aws7Q/management/topics/ibmmq/schema/value

```

# KSQL

# Create the stream from the CLICKSTREAM topic in C3

Make sure to leave the timestamp blank to use the topic timestamp by default

## add a message to DEV.QUEUE.1: `bobk_43` and `akatz1022`

## then create the Stream for the IBMMQ topic

```sql
CREATE STREAM ibmmq
  WITH (KAFKA_TOPIC='ibmmq',
        VALUE_FORMAT='AVRO');
```

# To join with clickstream put either one of these user ids into mq: `bobk_43` and `akatz1022`

## JOIN the 2 streams

```sql
select  * from  CLICKSTREAM
join  IBMMQ WITHIN 5 seconds
on text = username;
```
