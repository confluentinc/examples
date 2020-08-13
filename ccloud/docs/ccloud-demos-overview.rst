.. _ccloud-demos-overview:

|ccloud| Demos
==============

`Confluent Cloud <https://docs.confluent.io/current/cloud/index.html>`__ is a resilient, scalable streaming data service based on |ak|, delivered as a fully managed service. It has a web interface and local command-line interface that you can use to manage cluster resources, |ak| topics, |sr|, and other services.

This page describes a few resources to help you build and validate your solutions on |ccloud|.

.. include:: includes/ccloud-promo-code.rst

=======
Caution
=======

All the following demos and examples use real |ccloud| resources.
They create |ccloud| environments, clusters, topics, ACLs, service accounts, ksqlDB applications, and potentially other |ccloud| resources that are billable.
To avoid unexpected charges, carefully evaluate the cost of resources before launching any demo and manually verify that all |ccloud| resources are destroyed after you are done.


=====
Demos
=====

|ccloud| Quickstart
--------------------------

The :devx-examples:`Confluent Cloud Quickstart|cp-quickstart/` is an automated version of the :ref:`Confluent Platform Quickstart <quickstart>`, but this one runs in |ccloud|.

.. figure:: ../../cp-quickstart/images/quickstart.png

ccloud-stack Utility
--------------------

The :ref:`ccloud-stack` creates a stack of fully managed services in |ccloud|.
Executed with a single command, it is a quick way to create fully managed components in |ccloud|, which you can then use for learning and building other demos.
Do not use this in a production environment.
The script uses the |ccloud| CLI to dynamically do the following in |ccloud|:

-  Create a new environment.
-  Create a new service account.
-  Create a new Kafka cluster and associated credentials.
-  Enable |sr-ccloud| and associated credentials.
-  Create a new ksqlDB app and associated credentials.
-  Create ACLs with wildcard for the service account.
-  Generate a local configuration file with all above connection information, useful for other demos/automation.

.. figure:: images/ccloud-stack-resources.png



Client Code Examples
--------------------

If you are looking for code examples of producers writing to and consumers reading from |ccloud|, or producers and consumers using Avro with |sr-long|, refer to the :devx-examples:`client examples|clients/cloud/README.md`.
It provides client examples written in various programming languages.

.. figure:: ../../clients/cloud/images/clients-all.png

|ccloud| CLI
------------

The :devx-examples:`Confluent Cloud CLI demo|ccloud/beginner-cloud/README.md` is a fully scripted demo that shows users how to interact with |ccloud| using the |ccloud| CLI.
It steps through the following workflow:

-  Create a new environment and specify it as the default.
-  Create a new Kafka cluster and specify it as the default.
-  Create a user key/secret pair and specify it as the default.
-  Produce and consume with |ccloud| CLI.
-  Create a service account key/secret pair.
-  Run a Java producer: before and after ACLs.
-  Run a Java producer: showcase a Prefix ACL.
-  Run Connect and kafka-connect-datagen connector with permissions.
-  Run a Java consumer: showcase a Wildcard ACL.
-  Delete the API key, service account, Kafka topics, Kafka cluster, environment, and the log files.

Cloud ETL
---------

The :ref:`cloud ETL demo <cloud-etl>` showcases a cloud ETL solution leveraging all fully-managed services on |ccloud|.
Using |ccloud| CLI, the demo creates a source connector that reads data from an AWS Kinesis stream into |ccloud|, then a |ccloud| ksqlDB application processes that data, and then a sink connector writes the output data into cloud storage in the provider of your choice (GCP GCS, AWS S3, or Azure Blob).

.. figure:: ../../cloud-etl/docs/images/topology.png

Hybrid Cloud
------------

The :ref:`hybrid cloud demo <quickstart-demos-ccloud>` and playbook showcase a hybrid Kafka deployment: one cluster is a self-managed cluster running locally, the other is a |ccloud| cluster.
Data streams into topics, in both the local cluster and the |ccloud| cluster. |crep| copies the on-prem data to |ccloud| so that stream processing can happen in the cloud.

.. figure:: images/services-in-cloud.jpg

Microservices in the Cloud
--------------------------

The :ref:`microservices cloud demo <tutorial-microservices-orders>` showcases an order management workflow targeting |ccloud|.
Microservices are deployed locally on Docker, and they are configured to use a |ak| cluster, |ksqldb|, and |sr-long| in |ccloud|.
|kconnect-long| is also deployed locally on Docker, and it runs a SQL source connector to produce to |ccloud| and a Elasticsearch sink connector to consume from |ccloud|.

.. figure:: ../../microservices-orders/docs/images/microservices-demo.png

Confluent Operator with Cloud
-----------------------------

The :ref:`Kubernetes demo <quickstart-demos-operator-replicator-gke-cc>` features a deployment of |cp| on Google Kubernetes Engine (GKE) leveraging Confluent Operator and |crep|, highlighting a data replication strategy to |ccloud|.
Upon running this demo, you will have a GKE-based |cp| deployment with simulated data replicating to your |ccloud| cluster.

.. figure:: ../../kubernetes/replicator-gke-cc/docs/images/operator-demo-phase-2.png


=========================
Build Your Own Cloud Demo
=========================

ccloud-stack Utility
--------------------

The :ref:`ccloud-stack` creates a stack of fully managed services in |ccloud|.
Executed with a single command, it is a quick way to create fully managed components in |ccloud|, which you can then use for learning and building other demos.
Do not use this in a production environment.
The script uses the |ccloud| CLI to dynamically do the following in |ccloud|:

-  Create a new environment.
-  Create a new service account.
-  Create a new Kafka cluster and associated credentials.
-  Enable |sr-ccloud| and associated credentials.
-  Create a new ksqlDB app and associated credentials.
-  Create ACLs with wildcard for the service account.
-  Generate a local configuration file with all above connection information, useful for other demos/automation.

.. figure:: images/ccloud-stack-resources.png


Auto-generate Configurations to connect to |ccloud|
---------------------------------------------------

The :ref:`configuration generation script <auto-generate-configs>` reads a configuration file and auto-generates delta configurations for all |cp| components and clients.
Use these per-component configurations for |cp| components and clients connecting to |ccloud|:

* |cp| Components:

  * |sr|

  * |ksql-cloud| Data Generator

  * |ksql-cloud|

  * |crep-full|

  * |c3|

  * |kconnect-long|

  * Kafka connector

  * |ak| command line tools

* Kafka Clients:

  * Java (Producer/Consumer)

  * Java (Streams)

  * Python

  * .NET

  * Go

  * Node.js

  * C++

* OS:

  * ENV file


Self Managed Components to |ccloud|
-----------------------------------

This :devx-cp-all-in-one:`Docker-based environment|cp-all-in-one-cloud` can be used with |ccloud|.
The ``docker-compose.yml`` launches all services in |cp| (except for the Kafka brokers), runs them in containers on localhost, and automatically configures them to connect to |ccloud|.
Using this as a foundation, you can then add any connectors or applications.

.. figure:: images/cp-all-in-one-cloud.png


Put It All Together
-------------------

You can chain these utilities to build your own hybrid demos that span on-prem and |ccloud|, where some self-managed components run on-prem and fully-managed services run in |ccloud|.

For example, you may want an easy way to run a connector not yet available in |ccloud|.
In this case, you can run a self-managed connect worker and connector on prem and connect it to your |ccloud| cluster.
Or perhaps you want to build a |ak| demo in |ccloud| and run the |crest| client or |c3| against it.

You can build any demo with a mix of fully-managed services in |ccloud| and self-managed components on localhost, in a few easy steps.

#. Create a :ref:`ccloud-stack <ccloud-stack>` of fully managed services in |ccloud|. One of the outputs is a local configuration file with key-value pairs of the required connection values to |ccloud|. (If you already have provisioned your |ccloud| resources, you can skip this step).

   .. sourcecode:: bash

      ./ccloud_stack_create.sh

#. Run the :ref:`configuration generation script <auto-generate-configs>`, passing in that local configuration file (created in previous step) as input. This script generates delta configuration files for all |cp| components and clients, including information for bootstrap servers, endpoints, and credentials required to connect to |ccloud|.

   .. sourcecode:: bash

      # stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config is generated by step above
      ./ccloud-generate-cp-configs.sh stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config

   One of the generated delta configuration files from this step is for environment variables, and it resembles :devx-examples:`this example|ccloud/template_delta_configs/env.delta`, with credentials filled in.

   .. literalinclude:: ../template_delta_configs/env.delta

#. Source the above delta env file to export variables into the shell environment.

   .. sourcecode:: bash

      # delta_configs/env.delta is generated by step above
      source delta_configs/env.delta

#. Run the desired |cp| services locally using :devx-cp-all-in-one:`this Docker-based example|cp-all-in-one-cloud`. The Docker Compose file launches |cp| services on your localhost and uses environment variable substitution to populate the parameters with the connection values to your |ccloud| so that they can connect to |ccloud|. If you want to run a single service, you can bring up just that service.
 
   .. sourcecode:: bash

      docker-compose up -d <service>

   In the case of running a self-managed connector locally that connects to |ccloud|, first add your desired connector to the base |kconnect-long| Docker image as described in :ref:`connect_adding_connectors_to_images`, and then substitute that Docker image in your Docker Compose file.

#. Refer to the :devx-examples:`library of bash functions|utils/ccloud_library.sh` for examples on how to interact with |ccloud| via the |ccloud| CLI.


====================
Additional Resources
====================

-  For a practical guide to configuring, monitoring, and optimizing your |ak| client applications, see the `Best Practices for Developing Kafka Applications on Confluent Cloud <https://assets.confluent.io/m/14397e757459a58d/original/20200205-WP-Best_Practices_for_Developing_Apache_Kafka_Applications_on_Confluent_Cloud.pdf>`__ whitepaper.
-  Learn how to use |crep-full| to copy Kafka data to |ccloud|, in different configurations that allow |kconnect-long| to be backed to |ccloud| or to your origin Kafka cluster. See :ref:`replicator-to-cloud-configurations` for more information.


.. toctree::
    :maxdepth: 1
    :hidden:

    ../../ccloud/docs/ccloud-stack
    ../../clients/docs/clients-all-examples
    ../../ccloud/docs/index
    ../../cloud-etl/docs/index
    ../../microservices-orders/docs/index
    ../../kubernetes/replicator-gke-cc/docs/index
    ../../ccloud/docs/replicator-to-cloud-configuration-types

