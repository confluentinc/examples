![image](../images/confluent-logo-300-2.png)

# Pre-requisites

* Docker version 17.06.1-ce
* Docker Compose version 1.14.0 with Docker Compose file format 2.1
* [Confluent Cloud CLI](https://docs.confluent.io/current/cloud-quickstart.html#step-2-install-ccloud-cli?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-all-in-one-cloud)
* [An initialized Confluent Cloud cluster used for development only](https://confluent.cloud)

# Setup

Note: Use this in a *non-production* Confluent Cloud instance for development purposes only.

## Step 1

On the host from which you are running Docker, ensure that you have properly initialized Confluent Cloud CLI and have a valid configuration file at `$HOME/.ccloud/config`. Example file:

```bash
$ cat $HOME/.ccloud/config
bootstrap.servers=<BROKER ENDPOINT>
ssl.endpoint.identification.algorithm=https
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";

# If you are using Confluent Cloud Schema Registry, add the following configuration parameters
basic.auth.credentials.source=USER_INFO
schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
schema.registry.url=https://<SR ENDPOINT>
```

## Step 2

By default, the demo uses Confluent Schema Registry running in a local Docker container. If you prefer to use Confluent Cloud Schema Registry instead, you need to first set it up:

   a. [Enable](http://docs.confluent.io/current/quickstart/cloud-quickstart.html#step-3-configure-sr-ccloud?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-all-in-one-cloud) Confluent Cloud Schema Registry prior to running the demo

   b. Validate your credentials to Confluent Cloud Schema Registry

   ```bash
   $ curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects
   ```

## Step 3

Generate a file of ENV variables used by Docker to set the bootstrap servers and security configuration.
(See [documentation](https://docs.confluent.io/current/cloud/connect/auto-generate-configs.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-all-in-one-cloud) for more information on using this script.)

   a. If you want to use Confluent Schema Registry running in a local Docker container:

   ```bash
   $ ../ccloud/ccloud-generate-cp-configs.sh $HOME/.ccloud/config schema_registry_docker.config
   ```

   b. If you want to use Confluent Cloud Schema Registry:

   ```bash
   $ ../ccloud/ccloud-generate-cp-configs.sh $HOME/.ccloud/config
   ```

## Step 4

Source the generated file of ENV variables

```bash
$ source ./delta_configs/env.delta
```

# Bring up services

Make sure you completed the steps in the Setup section above before proceeding. 

You may bring up all services in the Docker Compose file at once or individually.

## All services at once

```bash
$ docker-compose up -d
```

## Confluent Schema Registry

If you are not using Confluent Cloud Schema Registry:

```bash
$ docker-compose up -d schema-registry
```

## Kafka Connect

```bash
$ docker-compose up -d connect
```

## Confluent Control Center

```bash
$ docker-compose up -d control-center
```

## KSQL Server

```bash
$ docker-compose up -d ksql-server
```

## KSQL CLI

```bash
$ docker-compose up -d ksql-cli
```

## Confluent REST Proxy

```bash
$ docker-compose up -d rest-proxy
```
