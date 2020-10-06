.. _ccloud-stack:

ccloud-stack Utility for |ccloud|
=================================

========
Overview
========

This ``ccloud-stack`` utility creates a stack of fully managed services in |ccloud|.
It is a quick way to create fully managed resources in |ccloud|, which you can then use for learning and building other demos. 
The utility uses |ccloud| CLI under the hood to dynamically do the following in |ccloud| :

-  Create a new environment
-  Create a new service account
-  Create a new Kafka cluster and associated credentials
-  Enable Schema Registry and associated credentials
-  Create a new ksqlDB app and associated credentials
-  Create ACLs with wildcard for the service account

.. figure:: images/ccloud-stack-resources.png 

In addition to creating these resources, ``ccloud-stack`` also generates a local configuration file with connection information to all of the above services.
This file is particularly useful because it contains connection information to your |ccloud| instance, and any downstream application or |ak| client can use it, or you can use it for other demos or automation workflows.

.. include:: includes/ccloud-promo-code.rst

=======
Caution
=======

This utility uses real |ccloud| resources.
To avoid unexpected charges, carefully evaluate the cost of resources before launching the utility and ensure all resources are destroyed after you are done running it.

=============
Prerequisites
=============

- Create a user account in `Confluent Cloud <https://www.confluent.io/confluent-cloud/>`__
- Local install of `Confluent Cloud CLI <https://docs.confluent.io/ccloud-cli/current/install.html>`__ v1.13.0 or later.
- ``jq`` tool


.. _ccloud-stack-usage:

=====
Usage
=====

Setup
-----

#. .. include:: ../../clients/docs/includes/clients-checkout.rst

#. Change directory to the ccloud-stack utility:

   .. code-block:: bash

      cd ccloud/ccloud-stack/

#. Log in to |ccloud| with the command ``ccloud login``, and use your |ccloud| username and password. The ``--save`` argument saves your |ccloud| user login credentials or refresh token (in the case of SSO) to the local ``netrc`` file.

   .. code:: shell

      ccloud login --save


Create a ccloud-stack
---------------------

#. By default, the ``cloud-stack`` utility creates resources in the cloud provider ``aws`` in region ``us-west-2``. If this is the target provider and region, create the stack by calling the bash script :devx-examples:`ccloud_stack_create.sh|ccloud/ccloud-stack/ccloud_stack_create.sh`. For more options when configuring your ``ccloud-stack``, see :ref:`ccloud-stack-options`.

   .. code:: bash

      ./ccloud_stack_create.sh

#. In addition to creating all the resources in |ccloud| with associated service account and ACLs, running ``ccloud-stack`` also generates a local configuration file with all the |ccloud| connection information, which is useful for other demos/automation. View this file at ``stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config``. It resembles:

   .. code-block:: text

      # ------------------------------
      # ENVIRONMENT ID: <ENVIRONMENT ID>
      # SERVICE ACCOUNT ID: <SERVICE ACCOUNT ID>
      # KAFKA CLUSTER ID: <KAFKA CLUSTER ID>
      # SCHEMA REGISTRY CLUSTER ID: <SCHEMA REGISTRY CLUSTER ID>
      # KSQLDB APP ID: <KSQLDB APP ID>
      # ------------------------------
      security.protocol=SASL_SSL
      sasl.mechanism=PLAIN
      bootstrap.servers=<BROKER ENDPOINT>
      sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
      basic.auth.credentials.source=USER_INFO
      schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
      schema.registry.url=https://<SR ENDPOINT>
      ksql.endpoint=<KSQLDB ENDPOINT>
      ksql.basic.auth.user.info=<KSQLDB API KEY>:<KSQLDB API SECRET>


Destroy a ccloud-stack
----------------------

#. To destroy a ``cloud-stack`` created in the previous step, call the bash script :devx-examples:`ccloud_stack_destroy.sh|ccloud/ccloud-stack/ccloud_stack_destroy.sh` and pass in the client properties file auto-generated in the step above.

   .. code:: bash

      ./ccloud_stack_destroy.sh stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config


.. _ccloud-stack-options:

================
Advanced Options
================

Select Cloud Provider and Region
--------------------------------

By default, the ``cloud-stack`` utility creates resources in the cloud provider ``aws`` in region ``us-west-2``. To create resources in another cloud provider or region other than the default, complete the following steps:

#. View the available cloud providers and regions using the |ccloud| CLI:

   .. code-block:: bash

      ccloud kafka region list

#. Create the ``ccloud-stack`` and override the parameters ``CLUSTER_CLOUD`` and ``CLUSTER_REGION``, as shown in the following example:

   .. code-block:: bash

      CLUSTER_CLOUD=aws CLUSTER_REGION=us-west-2 ./ccloud_stack_create.sh

Use Existing Environment
------------------------

By default, a new ``ccloud-stack`` creates a new environment. To reuse an existing environment, create the ``ccloud-stack`` and override the parameter ``ENVIRONMENT`` with an existing environment ID, as shown in the following example:

.. code-block:: bash

   ENVIRONMENT=env-oxv5x ./ccloud_stack_create.sh


===================
Automated Workflows
===================

If you don't want to create and destroy a ``ccloud-stack`` using the provided bash scripts :devx-examples:`ccloud_stack_create.sh|ccloud/ccloud-stack/ccloud_stack_create.sh` and :devx-examples:`ccloud_stack_destroy.sh|ccloud/ccloud-stack/ccloud_stack_destroy.sh`, you may pull in the :devx-examples:`ccloud_library|utils/ccloud_library.sh` and call the functions ``ccloud::create_ccloud_stack()`` and ``ccloud::destroy_ccloud_stack()`` directly.

#. Get the :devx-examples:`ccloud_library|utils/ccloud_library.sh`:

   .. code:: bash

      wget -O ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh

#. Source the library

   .. code:: bash

      source ./ccloud_library.sh

#. Run the bash functions directly from the command line. To create the ``cloud-stack``:

   .. code:: bash

      CLUSTER_CLOUD=aws
      CLUSTER_REGION=us-west-2 
      ccloud::create_ccloud_stack


   To destroy the ``ccloud-stack``:

   .. code:: bash

      ccloud::destroy_ccloud_stack


====================
Additional Resources
====================

- For a practical guide to configuring, monitoring, and optimizing your Kafka
  client applications when using |ccloud|, see `Developing Client Applications on Confluent Cloud <https://docs.confluent.io/cloud/best-practices/index.html>`__.
- Read this blog post about `using Confluent Cloud to manage data pipelines that use both on-premise and cloud deployments <https://www.confluent.io/blog/multi-cloud-integration-across-distributed-systems-with-kafka-connect/>`__.
- For sample usage of ``ccloud-stack``, see :ref:`ccloud-demos-overview` .
