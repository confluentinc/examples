![image](../../images/confluent-logo-300-2.png)

# Fully Managed Stack in Confluent Cloud

## Overview

The [ccloud stack](ccloud_stack_create.sh) is a script that creates a stack of fully managed services in Confluent Cloud.
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

## Create

To create the stack:

```bash
./ccloud_stack_create.sh
```

## Destroy

To destroy the stack, pass the client properties file auto-generated in the step above:

```bash
./ccloud stack_destroy.sh stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config
```

# Other Resources

See other [Confluent Cloud demos](../README.md).
