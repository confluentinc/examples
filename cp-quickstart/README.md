![image](../images/confluent-logo-300-2.png)

# Overview

The Confluent Platform Quickstart demo is the automated version of the [Confluent Platform Quickstart](https://docs.confluent.io/current/quickstart.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.cp-quickstart)

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

* Confluent Cloud similar quickstart to Confluent Platform: run the command below and then open your browser and navigate to Confluent Cloud at https://confluent.cloud .  If you choose to run it against your Confluent Cloud cluster, be aware that it creates resources and incurs charges.  It is for demo purposes only and should be used only for development.

```bash
./start-docker-cloud.sh
```
