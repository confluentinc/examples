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

This example uses real resources in Confluent Cloud, and it creates and deletes topics, service accounts, API keys, and ACLs.

### Pre-requisites

* Access to a Confluent Cloud cluster
* Local install of [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html#ccloud-install-cli?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud) v1.7.0 or later
* Confluent Cloud user credentials saved in `~/.netrc` (save with command `ccloud login --save`)
* Docker and Docker Compose for the local Connect worker
* `timeout` installed on your host
* `mvn` installed on your host
* `jq` installed on your host

### Confluent Cloud Promo Code

The first 20 users to sign up for [Confluent Cloud](https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud) and use promo code ``C50INTEG`` will receive an additional $50 free usage ([details](https://www.confluent.io/confluent-cloud-promo-disclaimer/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud)).

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

```bash
./cleanup.sh
```

# Additional Resources

* Refer to [Best Practices for Developing Kafka Applications on Confluent Cloud](https://assets.confluent.io/m/14397e757459a58d/original/20200205-WP-Best_Practices_for_Developing_Apache_Kafka_Applications_on_Confluent_Cloud.pdf?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud) whitepaper for a practical guide to configuring, monitoring, and optimizing your Kafka client applications when using Confluent Cloud.
* See other [Confluent Cloud demos](../README.md).
