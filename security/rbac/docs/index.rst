.. _rbac_demo:

RBAC Demo
=========

This demo showcases the |rbac-long| functionality in |cp|.
It is mostly for reference to see a workflow using the new |rbac| feature across the services in |cp|.

There are two ways to run the demo.

-  :ref:`rbac_demo_local`
-  :ref:`rbac_demo_docker`


.. _rbac_demo_local:

===============================================
Run demo on local install of Confluent Platform
===============================================

This method of running the demo is for users who have `downloaded <https://www.confluent.io/download/>`__ |cp| to their local hosts.

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

       git clone git@github.com:confluentinc/examples.git
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

This method of running the demo is for users who have Docker.
This demo setup includes:

-  |zk|
-  Kafka with MDS, connected to the OpenLDAP
-  |sr|
-  KSQL
-  |kconnect-long|
-  |crest|
-  |c3|
-  OpenLDAP

Prerequisites
-------------

-  Docker (validated on Docker for Mac version 18.03.0-ce-mac60)
-  :ref:`Confluent CLI <cli-install>`:
   |confluent-cli| must be installed on your machine, version
   ``v0.127.0`` or higher (note: as of |cp| 5.3, the |confluent-cli| is a separate
   :ref:`download <cli-install>`


Image Versions
--------------

-  You can use production or pre-production images. This is configured
   via environment variables ``PREFIX`` and ``TAG``.

   -  ``PREFIX`` is appended before the actual image name, before ``/``
   -  ``TAG`` is a docker tag, appended after the ``:``
   -  E.g. with ``PREFIX=confluentinc`` and ``TAG=5.4.0``, kafka will
      use the following image: ``confluentinc/cp-server:5.4.0``
   -  If these variables are not set in the shell, they will be read
      from the ``.env`` file. Shell variables override whatever is set
      in the ``.env`` file
   -  You can also edit ``.env`` file directly
   -  This means all images would use the same tag and prefix. If you
      need to customize this behavior, edit the ``docker-compose.yml``
      file

Run the demo
------------

#. Clone the `confluentinc/examples <https://github.com/confluentinc/examples>`__ repository from GitHub and check out the :litwithvars:`|release|-post` branch.

   .. codewithvars:: bash

       git clone git@github.com:confluentinc/examples.git
       cd examples
       git checkout |release_post_branch|

#. Navigate to ``security/rbac/scripts`` directory.

   .. codewithvars:: bash

       cd security/rbac/rbac-docker

#. To start |cp|, run

   .. code:: bash

      ./confluent-start.sh

You can optionally pass in where ``-p project-name`` to name the
docker-compose project, otherwise it defaults to ``rbac``. You can use
standard docker-compose commands like this listing all containers:

.. code:: bash

   docker-compose -p rbac ps

or tail |c3| logs:

.. code:: bash

   docker-compose -p rbac logs --t 200 -f control-center
   
The Kafka broker is available at ``localhost:9094``, not ``localhost::9092``.

=============== ==================
Service         Host:Port
=============== ==================
Kafka           ``localhost:9094``
MDS             ``localhost:8090``
C3              ``localhost:9021``
Connect         ``localhost:8083``
KSQL            ``localhost:8088``
OpenLDAP        ``localhost:389``
Schema Registry ``localhost:8081``
=============== ==================

Grant Rolebindings
~~~~~~~~~~~~~~~~~~

#. Login to the MDS URL as ``professor:professor``, the configured super user, to grant initial role bindings

   .. code:: bash

      confluent login --url http://localhost:8090

#. Set ``KAFKA_CLUSTER_ID``

   .. code:: bash

      KAFKA_CLUSTER_ID=$(docker-compose -p rbac exec zookeeper zookeeper-shell localhost:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)

#. Grant ``User:bender`` ResourceOwner to prefix ``Topic:foo`` on Kafka cluster ``KAFKA_CLUSTER_ID``

   .. code:: bash

      confluent iam rolebinding create --principal User:bender --kafka-cluster-id $KAFKA_CLUSTER_ID --resource Topic:foo --prefix

#. List the roles of ``User:bender`` on Kafka cluster ``KAFKA_CLUSTER_ID``

   .. code:: bash

      confluent iam rolebinding list --principal User:bender --kafka-cluster-id $KAFKA_CLUSTER_ID 

#. The general listing syntax is:

   .. code:: bash

      confluent iam rolebinding list User:[username] [clusters and resources you want to view their roles on]

#. The general rolebinding syntax is:

   .. code:: bash

      confluent iam rolebinding create --role [role name] --principal User:[username] --resource [resource type]:[resource name] --[cluster type]-cluster-id [insert cluster id] 

#. Available role types and permissions can be found :ref:`here <rbac-predefined-roles>`.

#. Resource types include: Cluster, Group, Subject, Connector, TransactionalId, Topic.


Users
-----

=============== ============== ===========
Description     Name           Role
=============== ============== ===========
Super User      User:professor SystemAdmin
Connect         User:fry       SystemAdmin
Schema Registry User:leela     SystemAdmin
KSQL            User:zoidberg  SystemAdmin
C3              User:hermes    SystemAdmin
Test User       User:bender    <none>
=============== ============== ===========

User ``bender:bender`` doesn’t have any role bindings set up and can be used as a user under test

-  You can use ``./client-configs/bender.properties`` file to authenticate as ``bender`` from kafka console commands (like ``kafka-console-producer``, ``kafka-console-consumer``, ``kafka-topics`` and the like).
-  This file is also mounted into the broker docker container, so you can ``docker-compose -p [project-name] exec broker /bin/bash`` to open bash on broker and then use console commands with ``/etc/client-configs/bender.properties``.
-  When running console commands from inside the broker container, use ``localhost:9092``.
-  In this example, the ``bender`` client uses the token services for authentication (e.g. bender.properties uses ``sasl.mechanism=OAUTHBEARER``), for simplicity for this dev environment. But in production, the client should use Kerberos or mTLS for authentication.



==================
Additional Reading
==================

- :ref:`rbac-overview`
- `RBAC for Kafka Connect whitepaper <https://www.confluent.io/resources/rbac-for-kafka-connect>`__

