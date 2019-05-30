# Overview

Produce messages to and consume messages from [Confluent Cloud](https://www.confluent.io/confluent-cloud/) using [Kafka Connect Datagen](https://www.confluent.io/hub/confluentinc/kafka-connect-datagen)

*Note: Kafka Connect Datagen is meant for development purposes only and is not suitable for a production environment*


# Prerequisites

* [Confluent CLI](https://docs.confluent.io/current/cli/installing.html) installed on your machine, version 5.1.2 or higher. It is provided as part of the [Confluent Platform](https://www.confluent.io/download/).
* [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html) installed on your machine. It is provided as part of the Confluent Platform package or may be [installed separately](https://docs.confluent.io/current/cloud/cli/install.html).
* Access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/) cluster
* [Initialize](https://docs.confluent.io/current/cloud/cli/multi-cli.html#connect-ccloud-cli-to-a-cluster) your local Confluent Cloud configuration file using the `ccloud init` command, which creates the file at `$HOME/.ccloud/config`.
* Docker


# Example 1: Hello World!

In this example, the Kafka Connect Datagen connector writes Kafka data to a topic in Confluent Cloud. 
Each record is mock data generated using the [orders schema](https://github.com/confluentinc/kafka-connect-datagen/blob/master/src/main/resources/orders_schema.avro).
Use CLI to read that topic from Confluent Cloud.

1. Create the topic in Confluent Cloud

```bash
$ ccloud topic create test1
```

2. Generate a file of ENV variables used by Docker to set the bootstrap servers and security configuration.

```bash
$ ../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.ccloud/config
```

3. Source the generated file of ENV variables

```bash
$ source ./delta_configs/env.delta
```

4. Start Docker and note the `--build` argument which automatically pulls the Kafka Connect Datagen connector from Confluent Hub.

```bash
$ docker-compose up -d --build

Creating network "kafkaconnectdatagen_default" with the default driver
Building connect
Step 1/3 : FROM confluentinc/cp-kafka-connect:5.2.1
 ---> 4fbfbb11e4bf
Step 2/3 : ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"
 ---> Using cache
 ---> 13754183215d
Step 3/3 : RUN confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:latest
 ---> Running in 8181e89baf6c
Running in a "--no-prompt" mode 
Implicit acceptance of the license below:  
Apache License 2.0 
https://www.apache.org/licenses/LICENSE-2.0 
Downloading component Kafka Connect Datagen 0.1.3, provided by Confluent, Inc. from Confluent Hub and installing into /usr/share/confluent-hub-components 
Adding installation directory to plugin path in the following files: 
  /etc/kafka/connect-distributed.properties 
  /etc/kafka/connect-standalone.properties 
  /etc/schema-registry/connect-avro-distributed.properties 
  /etc/schema-registry/connect-avro-standalone.properties 
 
Completed 
Removing intermediate container 8181e89baf6c
 ---> b3c5a9e4a2d7
Successfully built b3c5a9e4a2d7
Successfully tagged confluentinc/kafka-connect-datagen:latest
Creating connect ... done
```

5. Wait ~60 seconds until Connect is ready, and confirm the Kafka Connect Datagen connector plugin is available.

```bash
$ docker-compose logs -f connect | grep "Finished starting connectors and tasks"
connect    | [2019-05-30 14:43:53,799] INFO Finished starting connectors and tasks (org.apache.kafka.connect.runtime.distributed.DistributedHerder)

$ docker-compose logs connect | grep "DatagenConnector"
connect    | [2019-05-30 14:43:41,167] INFO Added plugin 'io.confluent.kafka.connect.datagen.DatagenConnector' (org.apache.kafka.connect.runtime.isolation.DelegatingClassLoader)
connect    | [2019-05-30 14:43:42,614] INFO Added aliases 'DatagenConnector' and 'Datagen' to plugin 'io.confluent.kafka.connect.datagen.DatagenConnector' (org.apache.kafka.connect.runtime.isolation.DelegatingClassLoader)
```

6. Submit the kafka-connect-datagen connector.

```bash
$ ./submit_datagen_orders_config.sh 
```

7. Consume from topic `test1`. You should see messages as follows:

```bash
$ docker-compose exec connect bash -c 'kafka-console-consumer --topic test1 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer.config /tmp/connect-ccloud.delta --max-messages 5'

03153607,"orderid":3092,"itemid":"Item_659","orderunits":2.9849009420758397,"address":{"city":"City_74","state":"State_67","zipcode":42799}}}
{"schema":{"type":"struct","fields":[{"type":"int64","optional":false,"field":"ordertime"},{"type":"int32","optional":false,"field":"orderid"},{"type":"string","optional":false,"field":"itemid"},{"type":"double","optional":false,"field":"orderunits"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"city"},{"type":"string","optional":false,"field":"state"},{"type":"int64","optional":false,"field":"zipcode"}],"optional":false,"name":"ksql.address","field":"address"}],"optional":false,"name":"ksql.orders"},"payload":{"ordertime":15124
```

When you are done, press `<ctrl>-c`.

8. To demo the above commands, you may also run the provided script [start-docker.sh](start-docker.sh)


# Example 2: Avro And Confluent Cloud Schema Registry

This example is similar to the previous example, except the value is formatted as Avro and integrates with the Confluent Cloud Schema Registry.
Before using Confluent Cloud Schema Registry, check its [availability and limits](https://docs.confluent.io/current/cloud/limits.html).
Note that your VPC must be able to connect to the Confluent Cloud Schema Registry public internet endpoint.

1. As described in the [Confluent Cloud quickstart](https://docs.confluent.io/current/quickstart/cloud-quickstart.html), in the Confluent Cloud GUI, enable Confluent Cloud Schema Registry and create an API key and secret to connect to it.

2. Verify your Confluent Cloud Schema Registry credentials work from your host. In the output below, substitute your values for `<SR API KEY>`, `<SR API SECRET>`, and `<SR ENDPOINT>`.

    ```shell
    # View the list of registered subjects
    $ curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects
    ```

3. Add the following parameters to your local Confluent Cloud configuration file (``$HOME/.ccloud/config``). In the output below, substitute values for `<SR API KEY>`, `<SR API SECRET>`, and `<SR ENDPOINT>`.

    ```shell
    $ cat $HOME/.ccloud/config
    ...
    basic.auth.credentials.source=USER_INFO
    schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
    schema.registry.url=https://<SR ENDPOINT>
    ...
    ```

4. Create the topic in Confluent Cloud

```bash
$ ccloud topic create test2

5. Generate a file of ENV variables used by Docker to set the bootstrap servers and security configuration.

```bash
$ ../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.ccloud/config
```

6. Source the generated file of ENV variables

```bash
$ source ./delta_configs/env.delta
```

7. Start Docker and note the `--build` argument which automatically pulls the Kafka Connect Datagen connector from Confluent Hub.

```bash
$ docker-compose up -d --build

Creating network "kafkaconnectdatagen_default" with the default driver
Building connect
Step 1/3 : FROM confluentinc/cp-kafka-connect:5.2.1
 ---> 4fbfbb11e4bf
Step 2/3 : ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"
 ---> Using cache
 ---> 13754183215d
Step 3/3 : RUN confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:latest
 ---> Running in 8181e89baf6c
Running in a "--no-prompt" mode 
Implicit acceptance of the license below:  
Apache License 2.0 
https://www.apache.org/licenses/LICENSE-2.0 
Downloading component Kafka Connect Datagen 0.1.3, provided by Confluent, Inc. from Confluent Hub and installing into /usr/share/confluent-hub-components 
Adding installation directory to plugin path in the following files: 
  /etc/kafka/connect-distributed.properties 
  /etc/kafka/connect-standalone.properties 
  /etc/schema-registry/connect-avro-distributed.properties 
  /etc/schema-registry/connect-avro-standalone.properties 
 
Completed 
Removing intermediate container 8181e89baf6c
 ---> b3c5a9e4a2d7
Successfully built b3c5a9e4a2d7
Successfully tagged confluentinc/kafka-connect-datagen:latest
Creating connect ... done
```

8. Wait ~60 seconds until Connect is ready, and confirm the Kafka Connect Datagen connector plugin is available.

```bash
$ docker-compose logs -f connect | grep "Finished starting connectors and tasks"
connect    | [2019-05-30 14:43:53,799] INFO Finished starting connectors and tasks (org.apache.kafka.connect.runtime.distributed.DistributedHerder)

$ docker-compose logs connect | grep "DatagenConnector"
connect    | [2019-05-30 14:43:41,167] INFO Added plugin 'io.confluent.kafka.connect.datagen.DatagenConnector' (org.apache.kafka.connect.runtime.isolation.DelegatingClassLoader)
connect    | [2019-05-30 14:43:42,614] INFO Added aliases 'DatagenConnector' and 'Datagen' to plugin 'io.confluent.kafka.connect.datagen.DatagenConnector' (org.apache.kafka.connect.runtime.isolation.DelegatingClassLoader)
```

9. Submit the kafka-connect-datagen connector.

```bash
$ ./submit_datagen_orders_config_avro.sh 
```

10. Consume from topic `test2`. You should see messages as follows:

```bash
$ docker-compose exec connect bash -c 'kafka-avro-console-consumer --topic test2 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer.config /tmp/connect-ccloud.delta --property basic.auth.credentials.source=$CONNECT_VALUE_CONVERTER_BASIC_AUTH_CREDENTIALS_SOURCE --property schema.registry.basic.auth.user.info=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property schema.registry.url=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL --max-messages 5'
```

When you are done, press `<ctrl>-c`.

11. To demo the above commands, you may also run the provided script [start-docker-avro.sh](start-docker-avro.sh)

