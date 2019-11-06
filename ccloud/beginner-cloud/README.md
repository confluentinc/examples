![image](../../images/confluent-logo-300-2.png)

# Beginner Cloud

[start.sh](start.sh) is a fully scripted demo that shows users how to interact with Confluent Cloud using the CLI.
It steps through the following workflow.

* [Log in to Confluent Cloud](start.sh#L53)
* Create a demo environment and cluster, and specify them as the default
* Create create a user key/secret
* Create a Service Account and API key and secret
* Produce and consume with Confluent Cloud CLI
* Run a Java client: before and after ACLs
* Showcase a Prefix ACL
* Showcase a Wildcard ACL
* Run Connect and kafka-connect-datagen connector with permissions
* Delete the API key, service account, Kafka topics, and some of the local files

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
