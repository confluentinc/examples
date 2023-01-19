.. _ccloud-stack:

ccloud-stack Utility for |ccloud|
=================================

========
Overview
========

This ``ccloud-stack`` utility creates a stack of fully managed services in |ccloud|.
It is a quick way to create resources in |ccloud| with correct credentials and permissions, useful as a starting point from which you can then use for learning, extending, and building other examples.
The utility uses the Confluent CLI under the hood to dynamically do the following in |ccloud| :

-  Create a new environment
-  Create a new service account
-  Create a new Kafka cluster and associated credentials
-  Enable Schema Registry and associated credentials
-  (Optional) Create a new ksqlDB app and associated credentials
-  Create role binding for the service account

.. figure:: images/ccloud-stack-resources.png 

In addition to creating these resources, ``ccloud-stack`` also generates a local configuration file with connection information to all of the above services.
This file is particularly useful because it contains connection information to your |ccloud| instance, and any downstream application or |ak| client can use it, or you can use it for other demos or automation workflows.

========================
Cost to Run ccloud-stack
========================

Caution
-------

.. include:: includes/ccloud-examples-caution.rst

This utility uses real |ccloud| resources.
It is intended to be a quick way to create resources in |ccloud| with correct credentials and permissions, useful as a starting point from which you can then use for learning, extending, and building other examples.

- If you just run ``ccloud-stack`` without explicitly enabling |ccloud| ksqlDB, then there is no billing charge until you create a topic, produce data to the |ak| cluster, or provision any other fully-managed service.
- If you run ``ccloud-stack`` with enabling |ccloud| ksqlDB (1 CSU), then you will begin to accrue charges immediately.

Here is a list of Confluent CLI commands issued by the utility that create resources in |ccloud| (function ``ccloud::create_ccloud_stack()`` source code is in :devx-examples:`ccloud_library|utils/ccloud_library.sh`).
By default, the |ccloud| ksqlDB app is not created with ``ccloud-stack``, you have to explicitly enable it.

.. code-block:: text

   confluent iam service-account create $SERVICE_NAME --description "SA for $EXAMPLE run by $CCLOUD_EMAIL"  -o json

   confluent environment create $ENVIRONMENT_NAME -o json

   confluent kafka cluster create "$CLUSTER_NAME" --cloud $CLUSTER_CLOUD --region $CLUSTER_REGION
   confluent api-key create --service-account $SERVICE_ACCOUNT_ID --resource $RESOURCE -o json    // for kafka

   confluent iam rbac role-binding create --principal User:$SERVICE_ACCOUNT_ID --role EnvironmentAdmin --environment $ENVIRONMENT -o json

   confluent schema-registry cluster enable --cloud $SCHEMA_REGISTRY_CLOUD --geo $SCHEMA_REGISTRY_GEO -o json
   confluent api-key create --service-account $SERVICE_ACCOUNT_ID --resource $RESOURCE -o json    // for schema-registry

   # By default, ccloud-stack does not enable Confluent Cloud ksqlDB, but if you explicitly enable it:
   confluent ksql cluster create --cluster $CLUSTER --api-key "$KAFKA_API_KEY" --api-secret "$KAFKA_API_SECRET" --csu 1 -o json "$KSQLDB_NAME"
   confluent api-key create --service-account $SERVICE_ACCOUNT_ID --resource $RESOURCE -o json    // for ksqlDB REST API

|ccloud| Promo Code
-------------------

.. include:: includes/ccloud-examples-promo-code.rst


=============
Prerequisites
=============

- Create a user account in `Confluent Cloud <https://www.confluent.io/confluent-cloud/>`__
- Local install of the `Confluent CLI <https://docs.confluent.io/confluent-cli/current/install.html>`__ v2.2.0 or later.
- ``jq`` tool

Note that ``ccloud-stack`` has been validated on macOS 10.15.3 with bash version 3.2.57.
If you encounter issues on any other operating systems or versions, please open a GitHub issue at `confluentinc/examples <https://github.com/confluentinc/examples/issues>`__.


.. _ccloud-stack-usage:

=====
Usage
=====

Setup
-----

#. Clone the `confluentinc/examples <https://github.com/confluentinc/examples>`__
   GitHub repository and check out the
   :litwithvars:`|release|-post` branch.

   .. codewithvars:: bash

       git clone https://github.com/confluentinc/examples
       cd examples
       git checkout |release|-post

#. Change directory to the ccloud-stack utility:

   .. code-block:: bash

      cd ccloud/ccloud-stack/

#. Log in to |ccloud| with the command ``confluent login``, and use your |ccloud| username and password. The ``--save`` argument saves your |ccloud| user login credentials or refresh token (in the case of SSO) to the local ``.netrc`` file.

   .. code:: shell

      confluent login --save


Create a ccloud-stack
---------------------

#. By default, the ``cloud-stack`` utility creates resources in the cloud provider ``aws`` in region ``us-west-2``. If this is the target provider and region, create the stack by calling the bash script :devx-examples:`ccloud_stack_create.sh|ccloud/ccloud-stack/ccloud_stack_create.sh`. For more options when configuring your ``ccloud-stack``, see :cloud:`Advanced Options|getting-started/examples/ccloud/docs/ccloud-stack.html`.

   .. code:: bash

      ./ccloud_stack_create.sh

#. You will be prompted twice. Note the second prompt which is where you can optionally enable |ccloud| ksqlDB.

   .. code-block:: text

      Do you still want to run this script? [y/n] y
      Do you also want to create a Confluent Cloud ksqlDB app (hourly charges may apply)? [y/n] n

#. ``ccloud-stack`` assigns the `EnvironmentAdmin <https://docs.confluent.io/cloud/current/access-management/access-control/cloud-rbac.html#environmentadmin>`__ role to the service account it creates. This permissive role is useful for development and learning environments. In production, configure a stricter role and potentially use ACLs with RBAC as documented `here <https://docs.confluent.io/cloud/current/access-management/access-control/cloud-rbac.html#use-acls-with-rbac>`__.

#. In addition to creating all of the resources in |ccloud| with an associated service account, running ``ccloud-stack`` also generates a local configuration file with |ccloud| connection information, which is useful for creating demos or additional automation. View this file at ``stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config``. It resembles:

   .. code-block:: text

      # ------------------------------
      # ENVIRONMENT_ID: <ENVIRONMENT ID>
      # SERVICE_ACCOUNT_ID: <SERVICE ACCOUNT ID>
      # KAFKA_CLUSTER_ID: <KAFKA CLUSTER ID>
      # SCHEMA_REGISTRY_CLUSTER_ID: <SCHEMA REGISTRY CLUSTER ID>
      # KSQLDB_APP_ID: <KSQLDB APP ID>
      # ------------------------------
      sasl.mechanism=PLAIN
      security.protocol=SASL_SSL
      bootstrap.servers=<BROKER ENDPOINT>
      sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='<API KEY>' password='<API SECRET>';
      basic.auth.credentials.source=USER_INFO
      basic.auth.user.info=<SR API KEY>:<SR API SECRET>
      schema.registry.url=https://<SR ENDPOINT>
      replication.factor=3
      ksql.endpoint=<KSQLDB ENDPOINT>
      ksql.basic.auth.user.info=<KSQLDB API KEY>:<KSQLDB API SECRET>


.. _ccloud-stack-destroy:

Destroy a ccloud-stack
----------------------

#. To destroy a ``ccloud-stack`` created in the previous step, call the bash script :devx-examples:`ccloud_stack_destroy.sh|ccloud/ccloud-stack/ccloud_stack_destroy.sh` and pass in the client properties file auto-generated in the step above. By default, this deletes all resources, including the |ccloud| environment specified by the service account ID in the configuration file.

   .. code:: bash

      ./ccloud_stack_destroy.sh stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config

.. include:: includes/ccloud-examples-terminate.rst


.. _ccloud-stack-options:

================
Advanced Options
================

Select Cloud Provider and Region
--------------------------------

By default, the ``ccloud-stack`` utility creates resources in the cloud provider ``aws`` in region ``us-west-2``. To create resources in another cloud provider or region other than the default, complete the following steps:

#. View the available cloud providers and regions using the Confluent CLI:

   .. code-block:: bash

      confluent kafka region list

#. Create the ``ccloud-stack`` and override the parameters ``CLUSTER_CLOUD`` and ``CLUSTER_REGION``, as shown in the following example:

   .. code-block:: bash

      CLUSTER_CLOUD=aws CLUSTER_REGION=us-west-2 ./ccloud_stack_create.sh

Reuse Existing Environment
--------------------------

By default, a new ``ccloud-stack`` creates a new environment.
This means that, by default, ``./ccloud_stack_create.sh`` creates a new environment and ``./ccloud_stack_destroy.sh`` deletes the environment specified in the configuration file.
However, due to |ccloud| `environment limits per organization <https://docs.confluent.io/cloud/current/quotas/index.html#organization>`__, it may be desirable to work within an existing environment.

When you create a new stack, to reuse an existing environment, set the parameter ``ENVIRONMENT`` with an existing environment ID, as shown in the example:

.. code-block:: bash

   ENVIRONMENT=env-oxv5x ./ccloud_stack_create.sh

When you destroy resources that were created by ``ccloud-stack``, the default behavior is that the environment specified by the service account ID in the configuration file is deleted.
However, there are two additional options.

To preserve the environment when destroying all the other resources in the ``ccloud-stack``, set the parameter ``PRESERVE_ENVIRONMENT=true``, as shown in the following example.
If you do not specify ``PRESERVE_ENVIRONMENT=true``, then the environment specified by the service account ID in the configuration file is deleted.

.. code-block:: bash

   PRESERVE_ENVIRONMENT=true ./ccloud_stack_destroy.sh stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config

To destroy the environment when destroying all the other resources in the ``ccloud-stack``, but the service account is not part of the environment name (i.e., multiple ``ccloud-stacks`` were created in the same environment), set the parameter ``ENVIRONMENT_NAME_PREFIX=ccloud-stack-<SERVICE_ACCOUNT_ID>``, as shown in the following example.
Note that the service account ID in the environment name is not the same as the service account ID in the config name.
If you do not specify the environment name prefix, then the destroy function will not be able to identify the proper environment ID to delete.

.. code-block:: bash

   ENVIRONMENT_NAME_PREFIX=ccloud-stack-<SERVICE_ACCOUNT_ID_original> ./ccloud_stack_destroy.sh stack-configs/java-service-account-<SERVICE_ACCOUNT_ID_current>.config


Automated Workflows
-------------------

If you don't want to create and destroy a ``ccloud-stack`` using the provided bash scripts :devx-examples:`ccloud_stack_create.sh|ccloud/ccloud-stack/ccloud_stack_create.sh` and :devx-examples:`ccloud_stack_destroy.sh|ccloud/ccloud-stack/ccloud_stack_destroy.sh`, you may pull in the :devx-examples:`ccloud_library|utils/ccloud_library.sh` and call the functions ``ccloud::create_ccloud_stack()`` and ``ccloud::destroy_ccloud_stack()`` directly.

#. Get the :devx-examples:`ccloud_library|utils/ccloud_library.sh`:

   .. code:: bash

      curl -f -sS -o ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh

#. Source the library

   .. code:: bash

      source ./ccloud_library.sh

#. Optionally override the ``CLUSTER_CLOUD`` and ``CLUSTER_REGION`` configuration parameters.

   .. code:: bash

      CLUSTER_CLOUD=aws
      CLUSTER_REGION=us-west-2 

#. Run the bash function directly from the command line.

   To create the ``ccloud-stack`` without |ccloud| ksqlDB:

   .. code:: bash

      ccloud::create_ccloud_stack

   To create the ``ccloud-stack`` with |ccloud| ksqlDB:

   .. code:: bash

      ccloud::create_ccloud_stack true


#. To destroy the ``ccloud-stack``, run the following command. By default, it deletes all resources, including the |ccloud| environment specified by the service account ID in the configuration file.

   .. code:: bash

      ccloud::destroy_ccloud_stack $SERVICE_ACCOUNT_ID

====================
Additional Resources
====================

- For a practical guide to configuring, monitoring, and optimizing your Kafka
  client applications when using |ccloud|, see `Developing Client Applications on Confluent Cloud <https://docs.confluent.io/cloud/current/client-apps/index.html>`__.
- Read this blog post about `using Confluent Cloud to manage data pipelines that use both on-premise and cloud deployments <https://www.confluent.io/blog/multi-cloud-integration-across-distributed-systems-with-kafka-connect/>`__.
- For sample usage of ``ccloud-stack``, see :cloud:`Confluent Cloud Tutorials|get-started/cloud-demos.html` or :ref:`Observability for Apache Kafka® Clients to Confluent Cloud demo <ccloud-observability-index>`.
