![image](../../images/confluent-logo-300-2.png)

# Beginner Cloud

[start.sh](start.sh) is a fully scripted demo that shows users how to interact with Confluent Cloud using the CLI.
It steps through the following workflow.

* Log in to Confluent Cloud
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

## Usage

Option 1: Provide all arguments on command line

```bash
./start.sh <url to cloud> <cloud email> <cloud password>
```

Option 2: Provide all arguments on command line, except password for which you will be prompted

```bash
./start.sh <url to cloud> <cloud email>
```

## Pre-requisites

* Access to a Confluent Cloud cluster
* Local install of the new [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html#ccloud-install-cli) v0.192.0 or above
* Docker and Docker Compose
* `timeout` installed on your host
* `mvn` installed on your host
* `jq` installed on your host

# Other Resources

See other [Confluent Cloud demos](../README.md).
