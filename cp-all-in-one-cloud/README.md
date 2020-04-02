![image](../images/confluent-logo-300-2.png)

# Pre-requisites

* Docker version 17.06.1-ce
* Docker Compose version 1.14.0 with Docker Compose file format 2.1
* You must have access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-all-in-one-cloud) cluster
* Create a local file (e.g. at `$HOME/.confluent/java.config`) with configuration parameters to connect to your [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-all-in-one-cloud) Kafka cluster.  Follow [these detailed instructions](https://github.com/confluentinc/configuration-templates/tree/master/README.md) to properly create this file.

# Setup

Note: Use this in a *non-production* Confluent Cloud instance for development purposes only.

## Step 1

By default, the demo uses Confluent Schema Registry running in a local Docker container. If you prefer to use Confluent Cloud Schema Registry instead, you need to first set it up:

   a. [Enable](http://docs.confluent.io/current/quickstart/cloud-quickstart.html#step-3-configure-sr-ccloud?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-all-in-one-cloud) Confluent Cloud Schema Registry prior to running the demo

   b. Validate your credentials to Confluent Cloud Schema Registry

   ```bash
   $ curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects
   ```

## Step 2

Generate a file of ENV variables used by Docker to set the bootstrap servers and security configuration.
(See [documentation](https://docs.confluent.io/current/cloud/connect/auto-generate-configs.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-all-in-one-cloud) for more information on using this script.)

   a. If you want to use Confluent Schema Registry running in a local Docker container:

   ```bash
   $ ../ccloud/ccloud-generate-cp-configs.sh $HOME/.confluent/java.config schema_registry_docker.config
   ```

   b. If you want to use Confluent Cloud Schema Registry:

   ```bash
   $ ../ccloud/ccloud-generate-cp-configs.sh $HOME/.confluent/java.config
   ```

## Step 3

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
