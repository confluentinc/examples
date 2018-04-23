.. _quickstart-demos-ccloud:

Hybrid Kafka Clusters from Self-Host to Cloud
==============================================

This Confluent Cloud demo is the automated cloud version of the `Confluent Platform 4.1 Quickstart <https://docs.confluent.io/current/quickstart/ce-quickstart.html>`__ , whereby KSQL streaming runs on your Confluent Cloud cluster.

.. contents:: Contents
    :local:
    :depth: 2


========
Overview
========

This Confluent Cloud demo is the automated cloud version of the `KSQL Tutorial <https://docs.confluent.io/current/ksql/docs/tutorials/basics-local.html#create-a-stream-and-table>`__ , whereby KSQL streaming runs on your Confluent Cloud cluster.

You can monitor the KSQL stream in Confluent Control Center. Note that there will not be any details on the System Health pages about brokers or topics because Confluent Cloud does not provide the Confluent Metrics Reporter instrumentation outside of the Confluent Cloud.

This demo also showcases the Confluent Replicator executable for self-hosted Confluent to Confluent Cloud. This can be used for Disaster Recovery or other scenarios. In this case, Replicator is used to bootstrap the KSQL stream processing input Kafka topics `users` and `pageviews`.


.. figure:: images/ccloud-demo-diagram.jpg
    :alt: image


.. note:: This is a demo environment and has all services running on one host. Do not use this demo in production, and do not use `confluent cli` in production. This is meant exclusively to easily demo the |CP| and |cloud| with KSQL.


========
Run demo
========

**Demo validated with:**

-  Confluent Platform 4.1
-  Java version 1.8.0_162
-  MacOS 10.12
-  git
-  jq


1. Clone the `quickstart-demos GitHub repository <https://github.com/confluentinc/quickstart-demos>`__:

   .. sourcecode:: bash

     $ git clone https://github.com/confluentinc/quickstart-demos

2. Change directory to the Confluent Cloud demo

   .. sourcecode:: bash

     $ cd quickstart-demos/ccloud

3. Start the entire demo by running a single command that brings up the local "self-host" Confluent environment using `confluent cli, Confluent Replicator, and the KSQL streaming application. This will take less than 5 minutes to complete.

   .. sourcecode:: bash

      $ ./start.sh

4. Use Google Chrome to view the |c3| GUI at http://localhost:9021 . Click on the top right button that shows the current date, and change ``Last 4 hours`` to ``Last 30 minutes``.



========
Playbook
========

|c3|
--------------------------------


KSQL
----


Replicator
------------


========================
Troubleshooting the demo
========================

1. Because this demo uses Confluent CLI, all configuration files and log files are in the respective component subfolders in the current temp directory. Browse the current temp directory 

   .. sourcecode:: bash

        $ ls `confluent current`

        connect
        control-center
        kafka
        kafka-rest
        ksql-server
        schema-registry
        zookeeper


2. For example, to view the configuration and log file for Confluent Replicator:

   .. sourcecode:: bash

        $ ls `confluent current`/connect/replicator*

        replicator-to-ccloud-consumer.properties
        replicator-to-ccloud-producer.properties
        replicator-to-ccloud.properties
        replicator-to-ccloud.stdout


========
Teardown
========

1. Stop the demo, destroy all local components, delete topics backing KSQL queries.

   .. sourcecode:: bash

        $ ./stop.sh

2. Delete all topics in CCloud, including internal topics used for Confluent Control Center, Kafka Connect, KSQL, and Confluent Schema Registry.

   .. sourcecode:: bash

        $ ./ccloud-delete-all-topics.sh
