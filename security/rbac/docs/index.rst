.. _rbac_demo:

RBAC Demo
=========

This demo shows how to enable |rbac-long| functionality across |cp|.
It is for users who have `downloaded <https://www.confluent.io/download/>`__ |cp| to their local hosts.

.. seealso::

   For an |rbac| demo that is more representative of a real deployment of a |ak| event streaming application, see :ref:`cp-demo`, a Docker-based demo with |rbac| and other |cp| security features and LDAP integration.


.. _rbac_demo_local:

===============================================
Run demo on local install of Confluent Platform
===============================================

Caveats
-------

-  For simplicity, this demo does not use LDAP, instead it uses the Hash
   Login service with statically defined users/passwords. Additional
   configurations would be required if you wanted to augment the demo to
   connect to your LDAP server.
-  The |rbac| configurations and role bindings in this demo are not
   comprehensive, they are only for development to get minimum |rbac|
   functionality set up across all the services in |cp|.
   Please refer to the :ref:`RBAC documentation <rbac-overview>`
   for comprehensive configuration and production guidance.

Prerequisites
-------------

* :ref:`Confluent CLI <cli-install>`: |confluent-cli| must be installed on your machine, version ``v0.127.0`` or higher (note: as of |cp| 5.3, the |confluent-cli| is a separate :ref:`download <cli-install>`).

* `Confluent Platform 5.3 or higher <https://www.confluent.io/download/>`__: use a clean install of |cp| without modified properties files, or else the demo is not guaranteed to work.

* jq tool must be installed on your machine.

Run the demo
------------

#. Clone the `confluentinc/examples <https://github.com/confluentinc/examples>`__ repository from GitHub and check out the :litwithvars:`|release|-post` branch.

   .. codewithvars:: bash

       git clone https://github.com/confluentinc/examples.git
       cd examples
       git checkout |release_post_branch|

#. Navigate to ``security/rbac/scripts`` directory.

   .. codewithvars:: bash

       cd security/rbac/scripts

#. You have two options to run the demo.

   -  Option 1: run the demo end-to-end for all services

      .. code:: bash

         ./run.sh

   -  Option 2: step through it one service at a time
   
      .. code:: bash

         ./init.sh
         ./enable-rbac-broker.sh
         ./enable-rbac-schema-registry.sh
         ./enable-rbac-connect.sh
         ./enable-rbac-rest-proxy.sh
         ./enable-rbac-ksql-server.sh
         ./enable-rbac-control-center.sh

#. After you run the demo, view the configuration files:

   .. code:: bash

      # The original configuration bundled with Confluent Platform
      ls /tmp/original_configs/
   
   .. code:: bash

      # Configurations added to each service's properties file
      ls ../delta_configs/
   
   .. code:: bash

      # The modified configuration = original + delta
      ls /tmp/rbac_configs/

#. After you run the demo, view the log files for each of the services.
   Since this demo uses Confluent CLI, all logs are saved in a temporary
   directory specified by ``confluent local current``.

   .. code:: bash

      ls `confluent local current | tail -1`

   In that directory, you can step through the configuration properties for each of the services:

   .. code:: bash

      connect
      control-center
      kafka
      kafka-rest
      ksql-server
      schema-registry
      zookeeper
   
#. In this demo, the metadata service (MDS) logs are saved in a temporary directory.

   .. code:: bash

      cat `confluent local current | tail -1`/kafka/logs/metadata-service.log


Stop the demo
-------------

To stop the demo, stop |cp|, and delete files in ``/tmp/``.

.. code:: bash

   cd scripts
   ./cleanup.sh

Summary of Configurations and Role Bindings
-------------------------------------------

Here is a summary of the delta configurations and required role bindings, by service.

.. note:: For simplicity, this demo uses the Hash Login service instead of LDAP.  If you are using LDAP in your environment, extra configurations are required.

Broker
~~~~~~

- :devx-examples:`Additional RBAC configurations required for server.properties|security/rbac/delta_configs/server.properties.delta`
-  Role bindings:

   .. code:: bash
   
      # Broker Admin
      confluent iam rolebinding create --principal User:$USER_ADMIN_SYSTEM --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID
   
      # Producer/Consumer
      confluent iam rolebinding create --principal User:$USER_CLIENT_A --role ResourceOwner --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_CLIENT_A --role DeveloperRead --resource Group:console-consumer- --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

Schema Registry
~~~~~~~~~~~~~~~

- :devx-examples:`Additional RBAC configurations required for schema-registry.properties|security/rbac/delta_configs/schema-registry.properties.delta`
-  Role bindings:

   .. code:: bash
   
      # Schema Registry Admin
      confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Topic:_schemas --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_ADMIN_SCHEMA_REGISTRY --role ResourceOwner --resource Group:$SCHEMA_REGISTRY_CLUSTER_ID --kafka-cluster-id $KAFKA_CLUSTER_ID
   
      # Client connecting to Schema Registry
      confluent iam rolebinding create --principal User:$USER_CLIENT_A --role ResourceOwner --resource Subject:$SUBJECT --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID
   
Connect
~~~~~~~

- :devx-examples:`Additional RBAC configurations required for connect-avro-distributed.properties|security/rbac/delta_configs/connect-avro-distributed.properties.delta`
- :devx-examples:`Additional RBAC configurations required for a source connector|security/rbac/delta_configs/connector-source.properties.delta`
- :devx-examples:`Additional RBAC configurations required for a sink connector|security/rbac/delta_configs/connector-sink.properties.delta`
-  Role bindings:

   .. code:: bash

      # Connect Admin
      confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-configs --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-offsets --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:connect-statuses --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_ADMIN_CONNECT --role ResourceOwner --resource Group:connect-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role ResourceOwner --resource Topic:_confluent-secrets --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role ResourceOwner --resource Group:secret-registry --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User $USER_ADMIN_CONNECT --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID
   
      # Connector Submitter
      confluent iam rolebinding create --principal User:$USER_CONNECTOR_SUBMITTER --role ResourceOwner --resource Connector:$CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID
   
      # Connector
      confluent iam rolebinding create --principal User:$USER_CONNECTOR --role ResourceOwner --resource Topic:$TOPIC2_AVRO --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_CONNECTOR --role ResourceOwner --resource Subject:${TOPIC2_AVRO}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID

REST Proxy
~~~~~~~~~~

- :devx-examples:`Additional RBAC configurations required for kafka-rest.properties|security/rbac/delta_configs/kafka-rest.properties.delta`
-  Role bindings:

   .. code:: bash
   
      # REST Proxy Admin: no additional administrative rolebindings required because REST Proxy just does impersonation
   
      # Producer/Consumer
      confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role ResourceOwner --resource Topic:$TOPIC3 --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_CLIENT_RP --role DeveloperRead --resource Group:$CONSUMER_GROUP --kafka-cluster-id $KAFKA_CLUSTER_ID

KSQL
~~~~

- :devx-examples:`Additional RBAC configurations required for ksql-server.properties|security/rbac/delta_configs/kafka-rest.properties.delta`
-  Role bindings:

   .. code:: bash

      # KSQL Server Admin
      confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}_command_topic --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role SecurityAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID
      confluent iam rolebinding create --principal User:$USER_ADMIN_KSQL --role ResourceOwner --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID
   
      # KSQL CLI queries
      confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperWrite --resource KsqlCluster:ksql-cluster --kafka-cluster-id $KAFKA_CLUSTER_ID --ksql-cluster-id $KSQL_SERVICE_ID
      confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:${USER_KSQL} --role DeveloperRead --resource Topic:${KSQL_SERVICE_ID}ksql_processing_log --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role DeveloperRead --resource Group:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:${USER_KSQL} --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}transient --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID}transient --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:${USER_KSQL} --role ResourceOwner --resource Topic:${CSAS_STREAM1} --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:${CSAS_STREAM1} --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:${USER_KSQL} --role ResourceOwner --resource Topic:${CTAS_TABLE1} --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:${CTAS_TABLE1} --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:${USER_ADMIN_KSQL} --role ResourceOwner --resource Topic:_confluent-ksql-${KSQL_SERVICE_ID} --prefix --kafka-cluster-id $KAFKA_CLUSTER_ID

Control Center
~~~~~~~~~~~~~~

- :devx-examples:`Additional RBAC configurations required for control-center-dev.properties|security/rbac/delta_configs/control-center-dev.properties.delta`
-  Role bindings:

   .. code:: bash

      # Control Center Admin
      confluent iam rolebinding create --principal User:$USER_ADMIN_C3 --role SystemAdmin --kafka-cluster-id $KAFKA_CLUSTER_ID
   
      # Control Center user
      confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Topic:$TOPIC1 --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Topic:$TOPIC2_AVRO --kafka-cluster-id $KAFKA_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Subject:${TOPIC2_AVRO}-value --kafka-cluster-id $KAFKA_CLUSTER_ID --schema-registry-cluster-id $SCHEMA_REGISTRY_CLUSTER_ID
      confluent iam rolebinding create --principal User:$USER_CLIENT_C --role DeveloperRead --resource Connector:$CONNECTOR_NAME --kafka-cluster-id $KAFKA_CLUSTER_ID --connect-cluster-id $CONNECT_CLUSTER_ID
   
General Rolebinding Syntax
~~~~~~~~~~~~~~~~~~~~~~~~~~

#. The general rolebinding syntax is:

   .. code:: bash

      confluent iam rolebinding create --role [role name] --principal User:[username] --resource [resource type]:[resource name] --[cluster type]-cluster-id [insert cluster id] 

#. Available role types and permissions can be found :ref:`here <rbac-predefined-roles>`.

#. Resource types include: Cluster, Group, Subject, Connector, TransactionalId, Topic.


Listing a Users roles
~~~~~~~~~~~~~~~~~~~~~

General listing syntax:

.. code:: bash

   confluent iam rolebinding list User:[username] [clusters and resources you want to view their roles on]

For example, list the roles of ``User:bender`` on Kafka cluster ``KAFKA_CLUSTER_ID``

.. code:: bash

   confluent iam rolebinding list --principal User:bender --kafka-cluster-id $KAFKA_CLUSTER_ID 



.. _rbac_demo_docker:

==================
Run demo in Docker
==================

A Docker-based |rbac| demo is :ref:`cp-demo`.
It is representative of a real deployment of a |ak| event streaming application, with |rbac| and other |cp| security features and LDAP integration.


==================
Additional Reading
==================

- :ref:`rbac-overview`
- `RBAC for Kafka Connect whitepaper <https://www.confluent.io/resources/rbac-for-kafka-connect>`__

