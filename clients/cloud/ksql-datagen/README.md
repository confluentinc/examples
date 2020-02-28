# Overview

Produce messages to and consume messages from a Kafka cluster using the [KSQL datagen](https://docs.confluent.io/current/ksql/docs/tutorials/generate-custom-test-data.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud) command-line tool.

*Note: `ksql-datagen` is meant for development purposes only and is not suitable for a production environment*


# Prerequisites

* [Confluent Platform 5.4](https://www.confluent.io/download/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud)
* Docker
* Create a local file (e.g. at `$HOME/.confluent/java.config`) with configuration parameters to connect to your Kafka cluster, which can be on your local host, [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), or any other cluster.  Follow [these detailed instructions](https://github.com/confluentinc/configuration-templates/tree/master/README.md) to properly create this file. 
* If you are running on Confluent Cloud, you must have access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud) cluster

# Example 1: Hello World!

In this example, `ksql-datagen` writes Kafka data to a topic in Confluent Cloud. 
Each record is mock data generated using the [orders schema](https://github.com/confluentinc/ksql/blob/master/ksql-examples/src/main/resources/orders_schema.avro).
Use CLI to read that topic from Confluent Cloud.

1. Create the topic in Confluent Cloud

```bash
$ kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` --command-config $HOME/.confluent/java.config --topic test1 --create --replication-factor 3 --partitions 6
```

2. Generate a file of ENV variables used by Docker to set the bootstrap servers and security configuration.

```bash
$ ../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.confluent/java.config
```

3. Source the generated file of ENV variables

```bash
$ source ./delta_configs/env.delta
```

4. Start Docker.

```bash
$ docker-compose up -d
```

5. Consume from topic `test1`.

```bash
# Referencing a properties file
$ docker-compose exec connect bash -c 'kafka-console-consumer --topic test1 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer.config /tmp/ak-tools-ccloud.delta --max-messages 5'

# Referencing individual properties
$ docker-compose exec connect bash -c 'kafka-console-consumer --topic test1 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer-property ssl.endpoint.identification.algorithm=https --consumer-property sasl.mechanism=PLAIN --consumer-property security.protocol=SASL_SSL --consumer-property sasl.jaas.config="$SASL_JAAS_CONFIG_PROPERTY_FORMAT" --max-messages 5'
```

You should see messages as follows:

```bash
{"ordertime":1489322485717,"orderid":15,"itemid":"Item_352","orderunits":9.703502112840228,"address":{"city":"City_48","state":"State_21","zipcode":32731}}
```

When you are done, press `<ctrl>-c`.

6. To demo the above commands, you may also run the provided script [start-docker.sh](start-docker.sh)


# Example 2: Avro And Confluent Cloud Schema Registry

This example is similar to the previous example, except the value is formatted as Avro and integrates with the Confluent Cloud Schema Registry.
Before using Confluent Cloud Schema Registry, check its [availability and limits](https://docs.confluent.io/current/cloud/limits.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud).
Note that your VPC must be able to connect to the Confluent Cloud Schema Registry public internet endpoint.

1. As described in the [Confluent Cloud quickstart](https://docs.confluent.io/current/quickstart/cloud-quickstart/schema-registry.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud), in the Confluent Cloud GUI, enable Confluent Cloud Schema Registry and create an API key and secret to connect to it.

2. Verify your Confluent Cloud Schema Registry credentials work from your host. In the output below, substitute your values for `<SR API KEY>`, `<SR API SECRET>`, and `<SR ENDPOINT>`.

    ```shell
    # View the list of registered subjects
    $ curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects

    # Same as above, as a single bash command to parse the values out of $HOME/.confluent/java.config
    $ curl -u $(grep "^schema.registry.basic.auth.user.info" $HOME/.confluent/java.config | cut -d'=' -f2) $(grep "^schema.registry.url" $HOME/.confluent/java.config | cut -d'=' -f2)/subjects
    ```

3. Add the following parameters to your local Confluent Cloud configuration file (``$HOME/.confluent/java.config``). In the output below, substitute values for `<SR API KEY>`, `<SR API SECRET>`, and `<SR ENDPOINT>`.

    ```shell
    $ cat $HOME/.confluent/java.config
    ...
    basic.auth.credentials.source=USER_INFO
    schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
    schema.registry.url=https://<SR ENDPOINT>
    ...
    ```

4. Create the topic in Confluent Cloud

```bash
$ kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` --command-config $HOME/.confluent/java.config --topic test2 --create --replication-factor 3 --partitions 6
```

5. Generate a file of ENV variables used by Docker to set the bootstrap servers and security configuration.

```bash
$ ../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.confluent/java.config
```

6. Source the generated file of ENV variables

```bash
$ source ./delta_configs/env.delta
```

7. Start Docker.

```bash
$ docker-compose up -d
```

8. Consume from topic `test2`.

```bash
# Referencing a properties file
$ docker-compose exec connect bash -c 'kafka-avro-console-consumer --topic test2 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer.config /tmp/ak-tools-ccloud.delta --property basic.auth.credentials.source=$CONNECT_VALUE_CONVERTER_BASIC_AUTH_CREDENTIALS_SOURCE --property schema.registry.basic.auth.user.info=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property schema.registry.url=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL --max-messages 5'

# Referencing individual properties
$ docker-compose exec connect bash -c 'kafka-avro-console-consumer --topic test2 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer-property ssl.endpoint.identification.algorithm=https --consumer-property sasl.mechanism=PLAIN --consumer-property security.protocol=SASL_SSL --consumer-property sasl.jaas.config="$SASL_JAAS_CONFIG_PROPERTY_FORMAT" --property basic.auth.credentials.source=$CONNECT_VALUE_CONVERTER_BASIC_AUTH_CREDENTIALS_SOURCE --property schema.registry.basic.auth.user.info=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property schema.registry.url=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL --max-messages 5'
```

You should see messages as follows:

```bash
{"ordertime":{"long":1494153923330},"orderid":{"int":25},"itemid":{"string":"Item_441"},"orderunits":{"double":0.9910185646928878},"address":{"io.confluent.ksql.avro_schemas.KsqlDataSourceSchema_address":{"city":{"string":"City_61"},"state":{"string":"State_41"},"zipcode":{"long":60468}}}}
```

When you are done, press `<ctrl>-c`.

9. To demo the above commands, you may also run the provided script [start-docker-avro.sh](start-docker-avro.sh)

10. View the schema information registered in Confluent Cloud Schema Registry. In the output below, substitute values for `<SR API KEY>`, `<SR API SECRET>`, and `<SR ENDPOINT>`.

```bash
# View the list of registered subjects
$ curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects
["test2-value"]

# View the schema information for subject `test2-value`
$ curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects/test2-value/versions/1
{"subject":"test2-value","version":1,"id":100001,"schema":"{\"type\":\"record\",\"name\":\"KsqlDataSourceSchema\",\"namespace\":\"io.confluent.ksql.avro_schemas\",\"fields\":[{\"name\":\"ordertime\",\"type\":[\"null\",\"long\"],\"default\":null},{\"name\":\"orderid\",\"type\":[\"null\",\"int\"],\"default\":null},{\"name\":\"itemid\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"orderunits\",\"type\":[\"null\",\"double\"],\"default\":null},{\"name\":\"address\",\"type\":[\"null\",{\"type\":\"record\",\"name\":\"KsqlDataSourceSchema_address\",\"fields\":[{\"name\":\"city\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"state\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"zipcode\",\"type\":[\"null\",\"long\"],\"default\":null}]}],\"default\":null}]}"}
```
