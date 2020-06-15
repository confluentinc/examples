![image](../../images/confluent-logo-300-2.png)

# Fully Managed Stack in Confluent Cloud

## Overview

This script creates a stack of fully managed services in Confluent Cloud.
It is a quick way to create fully managed resources in Confluent Cloud, which you can then use for learning and building other demos.
Do not use this in a production environment.
The script uses the Confluent Cloud CLI to dynamically do the following in Confluent Cloud:

* Create a new environment
* Create a new service account
* Create a new Kafka cluster and associated credentials
* Enable Schema Registry and associated credentials
* Create a new ksqlDB app and associated credentials
* Create ACLs with wildcard for the service account
* Generate a local configuration file with all above connection information, useful for other demos/automation

## DISCLAIMER

This demo is learning purposes only.
If you choose to run it against your Confluent Cloud cluster, be aware that it creates resources and incurs charges.

## Pre-requisites

* User account on [Confluent Cloud](https://docs.confluent.io/current/cloud/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud-stacks)
* Local install of [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html#ccloud-install-cli?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud-stacks) v1.7.0 or later
* Confluent Cloud user credentials saved in `~/.netrc` (save with command `ccloud login --save`)

## Confluent Cloud Promo Code

The first 20 users to sign up for [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud-stacks) and use promo code ``C50INTEG`` will receive an additional $50 free usage ([details](https://www.confluent.io/confluent-cloud-promo-disclaimer/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud-stacks)).

## Create

To create the stack:

```bash
./ccloud_stack_create.sh
```

In addition to creating all the resources in Confluent Cloud with associated service account and ACLs, it also generates a local configuration file with all above connection information, useful for other demos/automation.
It is written to `stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config` and resembles:

```
# ------------------------------
# Confluent Cloud connection information for demo purposes only
# Do not use in production
# ------------------------------
# ENVIRONMENT ID: <ENVIRONMENT ID>
# SERVICE ACCOUNT ID: <SERVICE ACCOUNT ID>
# KAFKA CLUSTER ID: <KAFKA CLUSTER ID>
# SCHEMA REGISTRY CLUSTER ID: <SCHEMA REGISTRY CLUSTER ID>
# KSQLDB APP ID: <KSQLDB APP ID>
# ------------------------------
ssl.endpoint.identification.algorithm=https
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
bootstrap.servers=<BROKER ENDPOINT>
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
basic.auth.credentials.source=USER_INFO
schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
schema.registry.url=https://<SR ENDPOINT>
ksql.endpoint=<KSQLDB ENDPOINT>
ksql.basic.auth.user.info=<KSQLDB API KEY>:<KSQLDB API SECRET>
```

## Advanced usage

You may explicitly set the cloud provider and region. For example:

```bash
CLUSTER_CLOUD=aws CLUSTER_REGION=us-west-2 ./ccloud_stack_create.sh
```

Here are the variables and their default values:

| Variable | Default |
| --- | --- |
| CLUSTER_CLOUD | aws |
| CLUSTER_REGION | us-west-2 |

## Destroy

To destroy the stack, pass the client properties file auto-generated in the step above:

```bash
./ccloud stack_destroy.sh stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config
```

# Additional Resources

* Refer to [Best Practices for Developing Kafka Applications on Confluent Cloud](https://assets.confluent.io/m/14397e757459a58d/original/20200205-WP-Best_Practices_for_Developing_Apache_Kafka_Applications_on_Confluent_Cloud.pdf?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud) whitepaper for a practical guide to configuring, monitoring, and optimizing your Kafka client applications when using Confluent Cloud.

* See other [Confluent Cloud demos](../README.md).
