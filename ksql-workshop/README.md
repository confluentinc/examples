![image](../images/confluent-logo-300-2.png)

# Overview

This KSQL ratings demo showcases Kafka stream processing using KSQL. This demo was initially created for a KSQL workshop.

----

**You can follow the [step-by-step guide](ksql-workshop.adoc) workshop instructions here. These instructions are based on Docker instead of your local Confluent Platform install.**

----

As with the other demos in this repo, you may run the entire demo end-to-end with `./start.sh`, and it runs on your local Confluent Platform install instead of Docker.

![image](images/ksql_workshop_01.png)


# Prerequisites

* [Common demo prerequisites](https://github.com/confluentinc/examples#prerequisites)
* [Confluent Platform 5.0](https://www.confluent.io/download/)
* If you are running the [step-by-step guide](ksql-workshop.adoc)
  * Docker
  * Docker Compose
  * 8GB+ RAM

# What Should I see?

After you run `./start.sh`:

* If you are running Confluent Platform, open your browser and navigate to the Control Center web interface Monitoring -> Data streams tab at http://localhost:9021/monitoring/streams to see throughput and latency performance of the KSQL queries
* If you are running Confluent Platform, use Control Center to view and create KSQL queries. Otherwise, run the KSQL CLI `ksql http://localhost:8088`.
