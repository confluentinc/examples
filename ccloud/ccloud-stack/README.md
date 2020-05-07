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
* Create a new KSQL app and associated credentials
* Create ACLs with wildcard for the service account
* Generate a local configuration file with all above connection information, useful for other demos/automation

## DISCLAIMER

This demo is learning purposes only.
If you choose to run it against your Confluent Cloud cluster, be aware that it creates resources and incurs charges.
It is for demo purposes only and should be used only on a non-production cluster.

## Pre-requisites

* User account on [Confluent Cloud](https://docs.confluent.io/current/cloud/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud-stacks)
* Local install of the new [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html#ccloud-install-cli?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud-stacks) v1.0.0 or later
* Confluent Cloud user credentials saved in `~/.netrc` (save with command `ccloud login --save`)

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
# KSQL APP ID: <KSQL APP ID>
# ------------------------------
ssl.endpoint.identification.algorithm=https
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
bootstrap.servers=<BROKER ENDPOINT>
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
basic.auth.credentials.source=USER_INFO
schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
schema.registry.url=https://<SR ENDPOINT>
ksql.endpoint=<KSQL ENDPOINT>
ksql.basic.auth.user.info=<KSQL API KEY>:<KSQL API SECRET>
```

## Destroy

To destroy the stack, pass the client properties file auto-generated in the step above:

```bash
./ccloud stack_destroy.sh stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config
```

# Other Resources

See other [Confluent Cloud demos](../README.md).
