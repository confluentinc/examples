![image](../images/confluent-logo-300-2.png)

# Overview

The Confluent Platform Quickstart demo is the automated version of the [Confluent Platform Quickstart](https://docs.confluent.io/current/quickstart.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-quickstart)

![image](images/quickstart.png)

## Additional Examples

For additional examples that showcase streaming applications within an event streaming platform, please refer to [these demos](https://github.com/confluentinc/examples).

# Prerequisites

* [Common demo prerequisites](https://github.com/confluentinc/examples#prerequisites)
* [Confluent Platform 5.5](https://www.confluent.io/download/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-quickstart)

# Run demo

## Confluent Platform

* [Confluent Platform Quick Start](https://docs.confluent.io/current/quickstart/ce-quickstart.html#ce-quickstart?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-quickstart) for the local tarball install of Confluent Platform: run the command below and then open your browser and navigate to the Control Center at http://localhost:9021/:

```bash
./start.sh
```

* [Confluent Platform Quick Start](https://docs.confluent.io/current/quickstart/ce-docker-quickstart.html#ce-docker-quickstart?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-quickstart) for the Docker version of Confluent Platform: run the command below and then open your browser and navigate to the Control Center at http://localhost:9021/:

```bash
./start-docker.sh
```

* [Confluent Platform Quick Start](https://docs.confluent.io/current/quickstart/cos-docker-quickstart.html#cos-docker-quickstart?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-quickstart) for the Docker version of Confluent Platform with community components only: run the command below:

```bash
./start-docker-community.sh
```

## Confluent Cloud

* Confluent Cloud is a similar quickstart to Confluent Platform. After logging into the `ccloud` CLI, run the command below and open your browser navigating to https://confluent.cloud. Be aware the demo creates real cloud resources and incurs charges.  This is for demonstration purposes and should only be used for development environments.

* This demo also shows usage of the various data formats supported by Confluent Cloud, Schema Registry and ksqlDB.  The demo deploys a small ksqlDB application which builds streams and tables using Avro, Protobuf and JSON based formats.  The demo provides sample commands at the end of its startup showing how to consume Protobuf and Avro based data streams.

```bash
./start-docker-cloud.sh
```

### Advanced usage

You may explicitly set the cloud provider and region. For example:

```bash
CLUSTER_CLOUD=aws CLUSTER_REGION=us-west-2 ./start-docker-cloud.sh
```

Here are the variables and their default values:

| Variable | Default |
| --- | --- |
| CLUSTER_CLOUD | aws |
| CLUSTER_REGION | us-west-2 |

