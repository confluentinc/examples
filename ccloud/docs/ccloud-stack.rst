.. _ccloud-stack:

Fully Managed Stack in Confluent Cloud
======================================


========
Overview
========

If already have provisioned a |ccloud| cluster and created a service account and requisite ACLs to allow services to write data—awesome!
But if you would appreciate an assist, a very quick way to spin all this up is to use the ``ccloud-stack`` utility available in GitHub.

This ``ccloud-stack`` utility creates a stack of fully managed services in |ccloud|.
It is a quick way to create fully managed resources in |ccloud|, which you can then use for learning and building other demos. 
The script uses |ccloud| CLI under the hood to dynamically do the following in |ccloud| :

-  Create a new environment
-  Create a new service account
-  Create a new Kafka cluster and associated credentials
-  Enable Schema Registry and associated credentials
-  Create a new ksqlDB app and associated credentials
-  Create ACLs with wildcard for the service account

.. figure:: images/ccloud-stack-resources.png 

In addition to creating these resources, ``ccloud-stack`` also generates a local configuration file with connection information to all of the above services.
This file is particularly useful because it contains connection information to your |ccloud| instance, and any downstream application or |ak| client can use it, or you can use it for other demos or automation workflows.

=======
Caution
=======

This utility uses real |ccloud| resources.
To avoid unexpected charges, carefully evaluate the cost of resources before launching the utility and ensure all resources are destroyed after you are done running it.

=============
Prerequisites
=============

- Create a user account in `Confluent Cloud <https://confluent.cloud/>`__
- Local install of :ref:`Confluent Cloud CLI <ccloud-install-cli>` v1.13.0 or later.
- ``jq`` tool

.. include:: includes/ccloud-promo-code.rst

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

#. By default, the ``cloud-stack`` utility creates resources in the cloud provider ``aws`` in region ``us-west-2``. If this is the target provider and region, then create the stack with the following command.

   .. code:: bash

      ./ccloud_stack_create.sh

#. Alternatively, if you want to explicitly create resources in another cloud provider or region, use the |ccloud| CLI to view the available cloud providers and regions:

   .. code:: bash

      ccloud kafka region list

   Then create the ``ccloud-stack`` and override the parameters ``CLUSTER_CLOUD`` and ``CLUSTER_REGION``.

   .. code:: bash

      CLUSTER_CLOUD=aws CLUSTER_REGION=us-west-2 ./ccloud_stack_create.sh

#. In addition to creating all the resources in |ccloud| with associated service account and ACLs, it also generates a local configuration file with all above connection information, useful for other demos/automation. View this file at ``stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config``. It resembles:

   .. code-block:: text

      # ------------------------------
      # ENVIRONMENT ID: <ENVIRONMENT ID>
      # SERVICE ACCOUNT ID: <SERVICE ACCOUNT ID>
      # KAFKA CLUSTER ID: <KAFKA CLUSTER ID>
      # SCHEMA REGISTRY CLUSTER ID: <SCHEMA REGISTRY CLUSTER ID>
      # KSQLDB APP ID: <KSQLDB APP ID>
      # ------------------------------
      ssl.endpoint.identification.algorithm=https
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

#. To destroy a ``cloud-stack`` created in the previous step, and pass the client properties file auto-generated in the step above.

   .. code:: bash

      ./ccloud_stack_destroy.sh stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config

Source Code
===========

To see what is happening under the hood when you create or destroy a ``ccloud-stack``, view the source code in the :devx-examples:`ccloud_library|utils/ccloud_library.sh`.
Look for the function ``ccloud::create_ccloud_stack()`` and ``ccloud::destroy_ccloud_stack()``.


Additional Resources
====================

-  Refer to `Best Practices for Developing Kafka Applications on Confluent Cloud <https://assets.confluent.io/m/14397e757459a58d/original/20200205-WP-Best_Practices_for_Developing_Apache_Kafka_Applications_on_Confluent_Cloud.pdf?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.ccloud>`__ whitepaper for a practical guide to configuring, monitoring, and optimizing your Kafka client applications when using Confluent Cloud.

-  See other :ref:`ccloud-demos-overview` .
