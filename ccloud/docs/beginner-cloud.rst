
.. _beginner-cloud:

Confluent Cloud CLI
===================

Overview
--------

You can use `Confluent Cloud CLI
<https://docs.confluent.io/current/cloud/cli/install.html#ccloud-install-cli?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud>`__
to interact with your `Confluent Cloud
<https://confluent.cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud>`__
cluster.

`start.sh <start.sh>`__ is a fully scripted demo that shows you how to interact
with |ccloud|. Using the |ccloud| CLI, you can complete the following workflow
in about 8 minutes:

-  Create a new environment and specify it as the default
-  Create a new |ak| cluster and specify it as the default
-  Create a user key/secret pair and specify it as the default
-  Produce and consume with |ccloud| CLI
-  Create a service account key/secret pair
-  Run a Java producer: before and after ACLs
-  Run a Java producer: showcase a Prefix ACL
-  Run |kconnect| and kafka-connect-datagen connector with permissions
-  Run a Java consumer: showcase a Wildcard ACL
-  Delete the API key, service account, |ak| topics, |ak| cluster, environment,
   and the log files

Prerequisites
~~~~~~~~~~~~~~

-  Access to a |ccloud| cluster
-  Local install of `Confluent Cloud
   CLI <https://docs.confluent.io/current/cloud/cli/install.html#ccloud-install-cli?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud>`__
   v1.7.0 or later
-  |ccloud| user credentials saved in ``~/.netrc`` (save with command ``ccloud login --save``)
-  Docker and Docker Compose for the local |kconnect| worker
-  ``timeout`` installed on your host
-  ``mvn`` installed on your host
-  ``jq`` installed on your host

Confluent Cloud Promo Code
~~~~~~~~~~~~~~~~~~~~~~~~~~

The first 20 users to sign up for `Confluent Cloud
<https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud>`__
and use promo code ``C50INTEG`` will receive an additional $50 free usage
(`details
<https://www.confluent.io/confluent-cloud-promo-disclaimer/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud>`__).


Run the demo
------------

.. container:: message-status

   This example uses real resources in |ccloud|, and it creates and deletes
   topics, service accounts, API keys, and ACLs.

To run this demo, execute the following command:

.. code-block:: bash

      ./start.sh


Advanced demo usage
~~~~~~~~~~~~~~~~~~~

The demo script provides variables that allow you to alter the default |ak|
cluster name, cloud provider, and region. For example:

.. code-block:: bash

   CLUSTER_NAME=my-demo-cluster CLUSTER_CLOUD=aws CLUSTER_REGION=us-west-2 ./start.sh

Here are the variables and their default values:

.. list-table::
   :widths: 50 50
   :header-rows: 1

   * - Variable
     - Default
   * - ``CLUSTER_NAME``
     - demo-kafka-cluster
   * - ``CLUSTER_CLOUD``
     - aws
   * - ``CLUSTER_REGION``
     - us-west-2

Demo Cleanup
~~~~~~~~~~~~

If you run a demo that ends prematurely, you may receive the following error
message when trying to run the demo again (``ccloud environment create
demo-script-env``):

.. code-block:: text

      Error: 1 error occurred:
         * error creating account: Account name is already in use

      Failed to create environment demo-script-env. Please troubleshoot and run again

To perform demo cleanup, complete the following steps:

#. Delete the API keys and ACLs created in a previous demo run.

#. Run the following script to delete the demo’s topics, |ak| cluster, and environment.

   .. code-block:: bash

      ./cleanup.sh


Additional Resources
---------------------

-  See the `Best Practices for Developing Kafka Applications on
   Confluent Cloud
   <https://assets.confluent.io/m/14397e757459a58d/original/20200205-WP-Best_Practices_for_Developing_Apache_Kafka_Applications_on_Confluent_Cloud.pdf?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud>`__
   whitepaper for a guide to configuring, monitoring, and optimizing
   your |ak| client applications when using |ccloud|.

-  See other `Confluent Cloud demos <../README.md>`__.


