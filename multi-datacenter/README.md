![image](../images/confluent-logo-300-2.png)

# Overview

This demo deploys an active-active multi-datacenter design, with two instances of Confluent Replicator copying data bidirectionally between the datacenters.
Confluent Replicator (version 5.0.1 and higher) prevents cyclic repetition of data between the datacenters by using provenance information in the message headers.

NOTE: There is a [different demo](../multiregion/README.md) for Multi-Region Clusters (MRC) with follower fetching, observers, and replica placement.

## Documentation

* You can find the documentation for running this demo at [https://docs.confluent.io/platform/current/multi-dc-deployments/replicator/replicator-docker-tutorial.html](https://docs.confluent.io/platform/current/multi-dc-deployments/replicator/replicator-docker-tutorial.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.multi-datacenter)
* For a practical guide to designing and configuring multiple Apache Kafka clusters to be resilient in case of a disaster scenario, see the [Disaster Recovery white paper](https://www.confluent.io/white-paper/disaster-recovery-for-multi-datacenter-apache-kafka-deployments/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.multi-datacenter). This white paper provides a plan for failover, failback, and ultimately successful recovery.
