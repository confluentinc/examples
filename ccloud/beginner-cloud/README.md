![image](../../images/confluent-logo-300-2.png)

# Beginner Cloud

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

# Run the demo

## DISCLAIMER

This demo is for reference purposes only and should be used to see a sample workflow using Confluent Cloud CLI

If you choose to run it against your Confluent Cloud cluster, be aware that it:

- creates and deletes topics, service accounts, API keys, and ACLs
- is for demo purposes only
- should be used only on a non-production cluster

## Pre-requisites

* Access to a Confluent Cloud cluster
* Local install of the new [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html#ccloud-install-cli?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud) v1.0.0 or later
* Confluent Cloud user credentials saved in `~/.netrc` (save with command `ccloud login --save`)
* Docker and Docker Compose for the local Connect worker
* `timeout` installed on your host
* `mvn` installed on your host
* `jq` installed on your host

## Run demo

```bash
./start.sh
```

# Advanced demo usage

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

# Clean up after the demo

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


# Other Resources

See other [Confluent Cloud demos](../README.md).
