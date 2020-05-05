![image](../../images/confluent-logo-300-2.png)

# Confluent Cloud CLI

## Overview

You can use [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html#ccloud-install-cli?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud) to interact with your [Confluent Cloud](https://confluent.cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud) cluster.

[start.sh](start.sh) is a fully scripted demo that shows users how to interact with Confluent Cloud, stepping through the following workflow using the CLI, and it takes about 8 minutes to complete:

* Create a new environment and specify it as the default
* Create a new Kafka cluster and specify it as the default
* Create a user key/secret pair and specify it as the default
* Produce and consume with Confluent Cloud CLI
* Create a service account key/secret pair
* Run a Java producer: before and after ACLs
* Run a Java producer: showcase a Prefix ACL
* Run Connect and kafka-connect-datagen connector with permissions
* Run a Java consumer: showcase a Wildcard ACL
* Delete the API key, service account, Kafka topics, Kafka cluster, environment, and the log files

## Run the demo

### DISCLAIMER

This demo is for reference purposes only and should be used to see a sample workflow using Confluent Cloud CLI

If you choose to run it against your Confluent Cloud cluster, be aware that it:

- creates and deletes topics, service accounts, API keys, and ACLs
- is for demo purposes only
- should be used only on a non-production cluster

### Pre-requisites

* Access to a Confluent Cloud cluster
* Local install of the new [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html#ccloud-install-cli?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud) v1.0.0 or later
* Confluent Cloud user credentials saved in `~/.netrc` (save with command `ccloud login --save`)
* Docker and Docker Compose for the local Connect worker
* `timeout` installed on your host
* `mvn` installed on your host
* `jq` installed on your host

### Run demo

```bash
./start.sh
```

## Advanced demo usage

The demo script provides variables allowing you to alter the default Kafka cluster name, cloud provider, and region.  For example:

```bash
CLUSTER_NAME=my-demo-cluster CLUSTER_CLOUD=aws CLUSTER_REGION=us-west-2 ./start.sh
``` 

Here are the variables and their default values:
| Variable | Default |
| --- | --- |
| CLUSTER_NAME | demo-kafka-cluster |
| CLUSTER_CLOUD | aws |
| CLUSTER_REGION | us-west-2 |

## Clean up after the demo

If a demo run ended prematurely, it may not have totally cleaned up after itself and a new run may error out with the following message:

```bash
# Create and specify active environment
ccloud environment create demo-script-env
Error: 1 error occurred:
	* error creating account: Account name is already in use


Failed to create environment demo-script-env. Please troubleshoot and run again
```

You may need to manually delete API keys and ACLs created in a previous demo run.
But you could consider running the following script to delete the demo's topics, Kafka cluster, and environment.
Use this script with extreme caution and only in non-production environments.

```bash
./cleanup.sh
```

# Fully Managed Stack in Confluent Cloud

## Create the Stack

The [ccloud stack](beginner-cloud/ccloud_stack_spin_up.sh) is a script that uses the Confluent Cloud CLI to dynamically do the following things in Confluent Cloud:

* Create a new environment
* Create a new service account
* Create a new Kafka cluster and associated credentials
* Enable Schema Registry and associated credentials
* Create a new KSQL app and associated credentials
* Create ACLs with wildcard for the service account
* Generate a local configuration file with all above connection information, useful for other demos/automation

To spin up the stack:

```bash
./ccloud_stack_spin_up.sh
...
To spin down this stack, run './ccloud_stack_spin_down.sh /tmp/client-<SERVICE_ACCOUNT_ID>.config'
```

To spin down the stack:

```bash
./ccloud stack_spin_down.sh /tmp/client-<SERVICE_ACCOUNT_ID>.config
```

## Difference between demos

The difference between `ccloud_stack_spin_up.sh` and `start.sh` is that the former spins up all the resources in Confluent Cloud for use in downstream demos/automation, whereas the latter is just to show off step-by-step Confluent Cloud CLI commands and it cleans up after itself.

# Other Resources

See other [Confluent Cloud demos](../README.md).
