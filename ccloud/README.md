![image](../images/confluent-logo-300-2.png)

# Overview

This Confluent Cloud demo is the automated cloud version of the [Confluent Platform 4.1 Quickstart](https://docs.confluent.io/current/quickstart.html), whereby KSQL streaming runs on your Confluent Cloud cluster. You can monitor the KSQL streams in Confluent Control Center. Note that there will not be any details on the System Health pages about brokers or topics because Confluent Cloud does not provide the Confluent Metrics Reporter instrumentation outside of the Confluent Cloud.

This demo also showcases the Confluent Replicator executable for self-hosted Confluent to Confluent Cloud. This can be used for Disaster Recovery or other scenarios. In this case, Replicator is used to bootstrap the KSQL stream processing input Kafka topics `users` and `pageviews`.

![image](images/ccloud-demo-diagram.jpg)

# Prerequisites

* [Common demo prerequisites](https://github.com/confluentinc/quickstart-demos#prerequisites)
* [Confluent Platform 4.1: Enterprise](https://www.confluent.io/download/)
* [Confluent Cloud CLI](https://docs.confluent.io/current/cloud-quickstart.html#step-2-install-ccloud-cli)
* [An initialized Confluent Cloud cluster used for development only](https://confluent.cloud)

NOTE: Do not run this demo against a production Confluent Cloud cluster. Run it only in a cluster used for development only.

# What Should I see?

After you run `./start.sh`:

* If you are running Confluent Enterprise, open your browser and navigate to the Control Center web interface:
  *  Monitoring -> Data streams at http://localhost:9021/monitoring/streams to monitor throughput and latency performance of the KSQL queries
  *  Management -> Kafka Connect at http://localhost:9021/management/connect to monitor Replicator
* Run `ksql http://localhost:8089` to view and create queries, or open your browser and navigate to the KSQL UI at http://localhost:8089
* Run `ccloud topic list` to view all the new Kafka topics created on Confluent Cloud

In addition to running `./stop.sh` to stop the demo, you may also run `./ccloud-delete-all-topics.sh` to delete all topics used for Confluent Control Center, Kafka Connect, Confluent Schema Registry from your Confluent Cloud cluster.
