.. _quickstart-demos-ccloud:

On-Prem Kafka to Cloud
======================

This |ccloud| demo showcases a hybrid Kafka cluster: one cluster is a self-managed Kafka cluster running locally, the other is a |ccloud| cluster.
The use case is "Bridge to Cloud" as customers migrate from on premises to cloud.

.. figure:: images/services-in-cloud.jpg
    :alt: image

========
Overview
========

The major components of the demo are:

* Two Kafka clusters: one cluster is a self-managed cluster running locally, the other is a |ccloud| cluster.
* |c3|: manages and monitors the deployment. Use it for topic inspection, viewing the schema, viewing and creating ksqlDB queries, streams monitoring, and more.
* ksqlDB: Confluent Cloud ksqlDB running queries on input topics `users` and `pageviews` in |ccloud|.
* Two Kafka Connect clusters: one cluster connects to the local self-managed cluster and one connects to the |ccloud| cluster. Both Connect worker processes themselves are running locally.

  * One instance of `kafka-connect-datagen`: a source connector that produces mock data to prepopulate the topic `pageviews` locally
  * One instance of `kafka-connect-datagen`: a source connector that produces mock data to prepopulate the topic `users` in the |ccloud| cluster
  * Confluent Replicator: copies the topic `pageviews` from the local cluster to the |ccloud| cluster

* |sr-long|: the demo runs with Confluent Cloud Schema Registry, and the Kafka data is written in Avro format.

.. note:: This is a demo environment and has many services running on one host. Do not use this demo in production, and
          do not use Confluent CLI in production. This is meant exclusively to easily demo the |cp| and |ccloud|.

=======
Caution
=======

This demo uses real |ccloud| resources.
To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done running it.


=============
Prerequisites
=============

1. The following are prerequisites for the demo:

-  An initialized `Confluent Cloud cluster <https://confluent.cloud/>`__ used for development only. Do not use a production cluster.
-  `Confluent Cloud CLI <https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html#step-2-install-the-ccloud-cli>`__ v0.239.0 or later
-  `Download <https://www.confluent.io/download/>`__ |cp| if using the local install (not required for Docker)
-  jq

2. Create a |ccloud| configuration file with information on connecting to your Confluent Cloud cluster (see :ref:`auto-generate-configs` for more information).
By default, the demo looks for this configuration file at ``~/.ccloud/config``.

3. This demo has been validated with:

-  Docker version 17.06.1-ce
-  Docker Compose version 1.14.0 with Docker Compose file format 2.1
-  Java version 1.8.0_162
-  MacOS 10.12


========
Run demo
========

Setup
-----

#. By default, the demo reads the configuration parameters for your |ccloud| environment from a file at ``$HOME/.ccloud/config``. You can change this filename via the parameter ``CONFIG_FILE`` in :devx-examples:`config/demo.cfg|cloud-etl/config/demo.cfg`. Enter the configuration parameters for your |ccloud| cluster, replacing the values in ``<...>`` below particular for your |ccloud| environment:

   .. code:: shell

      $ cat $HOME/.ccloud/config
      bootstrap.servers=<BROKER ENDPOINT>
      ssl.endpoint.identification.algorithm=https
      security.protocol=SASL_SSL
      sasl.mechanism=PLAIN
      sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
      schema.registry.url=https://<SR ENDPOINT>
      schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
      basic.auth.credentials.source=USER_INFO
      ksql.endpoint=https://<ksqlDB ENDPOINT>
      ksql.basic.auth.user.info=<ksqlDB API KEY>:<ksqlDB API SECRET>

   To retrieve the values for the endpoints and credentials in the file above, find them using either the |ccloud| UI or |ccloud| CLI commands. If you have multiple |ccloud| clusters, make sure to use the one with the associated ksqlDB cluster.  The commands below demonstrate how to retrieve the values using the |ccloud| CLI.

   .. code:: shell

      # Login
      ccloud login --url https://confluent.cloud

      # BROKER ENDPOINT
      ccloud kafka cluster list
      ccloud kafka cluster use <id>
      ccloud kafka cluster describe <id>

      # SR ENDPOINT
      ccloud schema-registry cluster describe

      # ksqlDB ENDPOINT
      ccloud ksql app list

      # Credentials: API key and secret, one for each resource above
      ccloud api-key create

#. Clone the `examples GitHub repository <https://github.com/confluentinc/examples>`__ and check out the :litwithvars:`|release|-post` branch.

   .. codewithvars:: bash

     git clone https://github.com/confluentinc/examples
     cd examples
     git checkout |release|-post

#. Change directory to the |ccloud| demo.

   .. sourcecode:: bash

     $ cd ccloud

Run
---

#. Log in to |ccloud| with the command ``ccloud login``, and use your |ccloud| username and password.

   .. code:: shell

      ccloud login --url https://confluent.cloud


#. Start the entire demo by running a single command.  You have two choices: using a |cp| local install or Docker Compose. This will take less than 5 minutes to complete.

   .. sourcecode:: bash

      # For Confluent Platform local
      $ ./start.sh

      # For Docker Compose
      $ ./start-docker.sh

#. Log into the Confluent Cloud UI at http://confluent.cloud . Use Google Chrome to view the |c3| GUI at http://localhost:9021 . 



========
Playbook
========

|ccloud| CLI
-------------------

#. Validate you can list topics in your cluster.

   .. sourcecode:: bash

     ccloud kafka topic list

#. Get familiar with the |ccloud| CLI.  For example, create a new topic called ``test``, produce some messages to that topic, and then consume from that topic.

   .. sourcecode:: bash

     ccloud kafka topic create test
     ccloud kafka topic produce test
     ccloud kafka topic consume test -b



ksqlDB
------

#. From the Confluent Cloud UI, view the ksqlDB application flow.

   .. figure:: images/ksqlDB_flow.png
      :alt: image

#. Click on any stream to view its messages and its schema.

   .. figure:: images/ksqlDB_stream_messages.png
      :alt: image


Confluent Replicator
--------------------

Confluent Replicator copies data from a source Kafka cluster to a destination Kafka cluster.
In this demo, the source cluster is a local install of a self-managed cluster, and the destination cluster is |ccloud|.

#. |c3| is configured to manage the connect-cloud cluster running on port 8087, which is running a datagen connector and the |crep| connector. From the |c3| UI, view the connect clusters.

   .. figure:: images/c3_clusters.png
      :alt: image

#. Click on `replicator` to view the |crep| configuration. Notice that it is replicating the topic ``pageviews``.

   .. figure:: images/c3_replicator_config.png
      :alt: image

#. Validate that messages are replicated from the local ``pageviews`` topic to the Confluent Cloud ``pageviews`` topic. From the Confluent Cloud UI, view messages in this topic.

   .. figure:: images/cloud_pageviews_messages.png
      :alt: image


Confluent Schema Registry
-------------------------

The connectors used in this demo are configured to automatically write Avro-formatted data, leveraging the |ccloud| |sr|.

#. View all the |sr| subjects.

   .. sourcecode:: bash

        # Confluent Cloud Schema Registry
        $ curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects

#. From the Confluent Cloud UI, view the schema for the ``pageviews`` topic. The topic value is using a Schema registered with |sr| (the topic key is just a String).

   .. figure:: images/topic_schema.png
      :alt: image

#. If you need to migrate schemas from on-prem |sr| to |ccloud| |sr|, follow this :ref:`step-by-step guide <schemaregistry_migrate>`. Refer to the file :devx-examples:`submit_replicator_schema_migration_config.sh|ccloud/connectors/submit_replicator_schema_migration_config.sh#L13-L33>` for an example of a working Replicator configuration for schema migration.

===============================
Confluent Cloud Configurations
===============================

1. View the the template delta configuration for Confluent Platform components and clients to connect to Confluent Cloud:

   .. sourcecode:: bash

        $ ls template_delta_configs/

2. View your Confluent Cloud configuration file

   .. sourcecode:: bash

        $ cat $HOME/.ccloud/config

3. Generate the per-component delta configuration parameters, automatically derived from your Confluent Cloud configuration file:

   .. sourcecode:: bash

        $ ./ccloud-generate-cp-configs.sh

4. If you ran this demo as `start.sh` which uses Confluent CLI, it saves all configuration files and log files in the respective component subfolders in the current Confluent CLI temp directory (requires demo to be actively running):

   .. sourcecode:: bash

        # For Confluent Platform local install using Confluent CLI
        $ ls `confluent local current | tail -1`

5. If you ran this demo as `start-docker.sh`, the configuration is available in the `docker-compose.yml` file.

   ::

        # For Docker Compose
        $ cat docker-compose.yml



========================
Troubleshooting the demo
========================

1. If you can't run the demo due to error messages such as "'ccloud' is not found" or "'ccloud' is not initialized", validate that you have access to an initialized, working |ccloud| cluster and you have locally installed |ccloud| CLI.


2. To view log files, look in the current Confluent CLI temp directory (requires demo to be actively running):

   .. sourcecode:: bash

        # View all files
        $ ls `confluent local current | tail -1`

        # View log file per service, e.g. for the Kafka broker
        $ confluent local log kafka

3. If you ran with Docker, then run `docker-compose logs | grep ERROR`.


========
Teardown
========

1. Stop the demo, destroy all local components.

   .. sourcecode:: bash

      # For Confluent Platform local install using Confluent CLI
      $ ./stop.sh

      # For Docker Compose
      $ ./stop-docker.sh


2. Delete all |cp| topics in CCloud that this demo used, including topics used for |c3|, Kafka Connect, ksqlDB, and Confluent Schema Registry. Caution: this may have unintended consequence of deleting topics that you wanted to keep.

   .. sourcecode:: bash

        $ ./ccloud-delete-all-topics.sh

