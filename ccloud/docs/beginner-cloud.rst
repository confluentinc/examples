
.. _beginner-cloud:

Tuturial: |ccloud| CLI
=======================

Overview
--------

This tutorial will show you how to use the `Confluent Cloud CLI
<https://docs.confluent.io/current/cloud/cli/install.html>`__ to interact with
your `Confluent Cloud <https://confluent.cloud/login>`__ cluster.

After running `start.sh <start.sh>`__, you can complete the following workflow
in about 8 minutes using the |ccloud| CLI:

-  `Create a new environment and specify it as the default`_
-  `Create a new Kafka cluster and specify it as the default`_
-  `Create a user key/secret pair and specify it as the default`_
-  `Produce and consume with Confluent Cloud CLI`_
-  `Create a service account key/secret pair`_
-  `Run a Java producer before and after ACLs`_
-  `Run a Java producer to showcase a prefixed ACL`_
-  `Run Connect and kafka-connect-datagen connector with permissions`_
-  `Run a Java consumer to showcase a Wildcard ACL`_
-  `Delete the API key, service account, Kafka topics, Kafka cluster, environment,
   and the log files`_


Prerequisites
~~~~~~~~~~~~~~

-  Local install  `Confluent Cloud CLI <https://docs.confluent.io/current/cloud/cli/install.html>`__ v1.7.0 or later

.. You'll need to Follow the steps under the "Tools and client configuration" section in Confluent Cloud user interface
to install the Confluent Cloud CLI https://confluent.cloud/environments/env-nx63k/clusters/lkc-zjpm0/integrations/cli

-  Access to a `Confluent Cloud cluster <https://confluent.cloud/login>`__

.. maybe a add a caveat that says (follow the steps in the Confluent Cloud user interface to create a cluster if you haven't already created one)

-  |ccloud| user credentials saved in ``~/.netrc`` (save with command ``ccloud login --save``)
-  `Docker <https://docs.docker.com/get-docker/>`__ and `Docker Compose
   <https://docs.docker.com/compose/install/>`__ for the local |kconnect| worker
-  ``timeout`` installed on your host
-  `mvn <https://maven.apache.org/install.html>`__ installed on your host
-  `jq <https://stedolan.github.io/jq/>`__ installed on your host

Confluent Cloud Promo Code
~~~~~~~~~~~~~~~~~~~~~~~~~~

The first 20 users to sign up for `Confluent Cloud
<https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud>`__
and use promo code ``C50INTEG`` will receive an additional $50 free usage
(`details
<https://www.confluent.io/confluent-cloud-promo-disclaimer/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.beginner-cloud>`__).


Run the demo
------------

.. note::

   This example uses real resources in |ccloud|, and it creates and deletes
   topics, service accounts, API keys, and ACLs.

`start.sh <start.sh>`__ is a fully scripted demo that shows you how to interact
with |ccloud|.

To run the demo, execute the following command:

.. code-block:: bash

      ./start.sh

Now, you can complete the following workflow using the |ccloud| CLI.


Create a new environment and specify it as the default
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Run the following command to create a new |ccloud| environment
   ``demo-script-env``:

   .. code-block:: bash

      ccloud environment create demo-script-env -o json

#. Verify the output resembles:

   .. code-block:: text

      {
        "id": "env-5qz2q",
        "name": "demo-script-env"
      }


#. Specify ``env-5qz2q`` as the active environment by running the following
   command:

   .. code-block:: bash

       ccloud environment use env-5qz2q

   You should see the following message: ``Now using "env-5qz2q" as the default
   (active) environment.``


Create a new Kafka cluster and specify it as the default
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Run the following command to create a new |ccloud| cluster
   ``demo-kafka-cluster``:

   .. code-block:: bash

      ccloud kafka cluster create demo-kafka-cluster --cloud aws --region us-west-2

   .. note::

      It may take up to 5 minutes for the |ak| cluster to be ready.

#. Verify you see the following output:

   .. code-block:: text

      +--------------+---------------------------------------------------------+
      | Id           | lkc-x6m01                                               |
      | Name         | demo-kafka-cluster                                      |
      | Type         | BASIC                                                   |
      | Ingress      |                                                     100 |
      | Egress       |                                                     100 |
      | Storage      |                                                    5000 |
      | Provider     | aws                                                     |
      | Availability | LOW                                                     |
      | Region       | us-west-2                                               |
      | Status       | UP                                                      |
      | Endpoint     | SASL_SSL://pkc-4kgmg.us-west-2.aws.confluent.cloud:9092 |
      | ApiEndpoint  | https://pkac-ldgj1.us-west-2.aws.confluent.cloud        |
      +--------------+---------------------------------------------------------+

#. Specify ``lkc-x6m01`` as the active |ak|| cluster by running the following
   command:

   .. code-block:: bash

      ccloud kafka cluster use lkc-x6m01

   Running the previous command sets the |ak| cluster ``lkc-x6m01`` as the active
   cluster for environment ``env-5qz2``.


Create a user key/secret pair and specify it as the default
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Run the following command to create a user key/secret pair:

   .. code-block:: bash

      cloud api-key create --description "Demo credentials" --resource lkc-x6m01 -o json

#. Verify the output resembles:

   .. code-block:: text

      {
         "key": "QX7X4VA4DFJTTOIA",
         "secret": "fjcDDyr0Nm84zZr77ku/AQqCKQOOmb35Ql68HQnb60VuU+xLKiu/n2UNQ0WYXp/D"
      }

#. Associate the API key ``QX7X4VA4DFJTTOIA`` to the Kafka cluster ``lkc-x6m01``:

   .. code-block:: bash

      ccloud api-key use QX7X4VA4DFJTTOIA --resource lkc-x6m01

   Running the previoud command sets the API Key "QX7X4VA4DFJTTOIA" as the
   active API key for ``lkc-x6m0``.

#. Verify you see the following message:

   .. code-block:: text

      Waiting for Confluent Cloud cluster to be ready and for credentials to propagate
      ....

Produce and consume records with Confluent Cloud CLI
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Produce records
^^^^^^^^^^^^^^^

#. Run the following command to create a new Kafka topic ``demo-topic-1``:

   .. code-block:: bash

      ccloud kafka topic create demo-topic-1

#. Produce 10 messages to topic ``demo-topic-1`` by completing the following steps:

   a. Implement the following logic:

      .. code-block: bash

         (for i in `seq 1 10`; do echo "${i}" ; done) | \ timeout 10s

   b. Run the following command:

      .. code-block:: bash

         ccloud kafka topic produce demo-topic-1

#. Verify you see the following output:

   .. code-block:: text

      Starting Kafka Producer. ^C or ^D to exit
      1
      2
      3
      4
      5
      6
      7
      8
      9
      10

Consume records
^^^^^^^^^^^^^^^

#. Run the following command to consume messages from topic ``demo-topic-1``:

   .. code-block:: bash

      ccloud kafka topic consume demo-topic-1 -b

#. Verify you see the following output:

   .. code-block:: text

      Starting Kafka Consumer. ^C or ^D to exit
      2
      3
      9
      4
      5
      7
      10
      1
      6
      8


Create a service account key/secret pair
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Run the following commmand to create a new service account:

   .. code-block:: bash

      ccloud service-account create demo-app-3288 --description demo-app-3288 -o json

#. Verify the output resembles:

   .. code-block:: text

      {
         "id": 104349,
         "name": "demo-app-3288",
          "description": "demo-app-3288"
      }

#. Create an API key and secret for the service account ``104349`` by running
   the following account:

   .. code-block:: bash

      ccloud api-key create --service-account 104349 --resource lkc-x6m01 -o json

   .. code-block:: text

      {
        "key": "ESN5FSNDHOFFSUEV",
        "secret": "nzBEyC1k7zfLvVON3vhBMQrNRjJR7pdMc2WLVyyPscBhYHkMwP6VpPVDTqhctamB"
      }

#. Complete the following steps to create a local configuration file
   ``/tmp/client.config`` with |ccloud| connection information using the newly
   created API key and secret:

   a. Open the config file:

      cat /tmp/client.config

   b. Update  ``/tmp/client.config``  with the following parameters:

      .. code-block:: text

         ssl.endpoint.identification.algorithm=https
         sasl.mechanism=PLAIN
         security.protocol=SASL_SSL
         bootstrap.servers=pkc-4kgmg.us-west-2.aws.confluent.cloud:9092
         sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="ESN5FSNDHOFFSUEV" password\="nzBEyC1k7zfLvVON3vhBMQrNRjJR7pdMc2WLVyyPscBhYHkMwP6VpPVDTqhctamB";

   c. Wait 90 seconds for the service account credentials to propagate

   d. By default, no ACLs are configured. To confirm, run the following command:

      .. code-block:: bash

         ccloud kafka acl list --service-account 104349

      You should see the following output:

      .. code-block:: text

            ServiceAccountId | Permission | Operation | Resource | Name | Type
          +------------------+------------+-----------+----------+------+------+


Run a Java producer before and after configuring ACLs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Run the Java producer to ``demo-topic-1`` before configuring ACLs (expected to fail):

   .. code-block:: bash

      mvn -q -f ../../clients/cloud/java/pom.xml exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="/tmp/client.config demo-topic-1" -Dlog4j.configuration=file:log4j.properties > /tmp/log.1 2>&1

#. Verify you see ``org.apache.kafka.common.errors.TopicAuthorizationException``
   in the logs as shown in the following example (expected because there are no ACLs to allow this client application):

   .. code-block:: text

       PASS: Producer failed
       [ERROR] Failed to execute goal org.codehaus.mojo:exec-maven-plugin:1.2.1:java (default-cli) on project clients-example: An exception occured while executing the Java class. null: InvocationTargetException: java.util.concurrent.ExecutionException: org.apache.kafka.common.errors.TopicAuthorizationException: Authorization failed. -> [Help 1]

#. Run the following commands to create ACLs for the service account:

   .. code-block:: bash

      ccloud kafka acl create --allow --service-account 104349 --operation CREATE --topic demo-topic-1
      ccloud kafka acl create --allow --service-account 104349 --operation WRITE --topic demo-topic-1

#. Verify you see the following output:

   .. code-block:: text

         ServiceAccountId | Permission | Operation | Resource |     Name     |  Type
       +------------------+------------+-----------+----------+--------------+---------+
         User:104349      | ALLOW      | CREATE    | TOPIC    | demo-topic-1 | LITERAL

         ServiceAccountId | Permission | Operation | Resource |     Name     |  Type
       +------------------+------------+-----------+----------+--------------+---------+
         User:104349      | ALLOW      | WRITE     | TOPIC    | demo-topic-1 | LITERAL

#. Run the following command and verify the ACLs were configured:

   .. code-block:: bash

      ccloud kafka acl list --service-account 104349

   You should see:

   .. code-block:: text

         ServiceAccountId | Permission | Operation | Resource |     Name     |  Type
       +------------------+------------+-----------+----------+--------------+---------+
         User:104349      | ALLOW      | CREATE    | TOPIC    | demo-topic-1 | LITERAL
         User:104349      | ALLOW      | WRITE     | TOPIC    | demo-topic-1 | LITERAL

#. Run the Java producer to ``demo-topic-1`` after configuring the ACLs:

   .. code-block:: bash

      mvn -q -f ../../clients/cloud/java/pom.xml exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="/tmp/client.config demo-topic-1" -Dlog4j.configuration=file:log4j.properties > /tmp/log.2 2>&1

#. Verify you see the ``10 messages were produced to topic`` message in the logs as
   shown in the following example:

   .. code-block:: text

         PASS
         [2020-08-29 13:52:10,836] WARN The configuration 'sasl.jaas.config' was supplied but isn't a known config. (org.apache.kafka.clients.admin.AdminClientConfig)
         [2020-08-29 13:52:10,837] WARN The configuration 'ssl.endpoint.identification.algorithm' was supplied but isn't a known config. (org.apache.kafka.clients.admin.AdminClientConfig)
         Producing record: alice	{"count":0}
         Producing record: alice	{"count":1}
         Producing record: alice	{"count":2}
         Producing record: alice	{"count":3}
         Producing record: alice	{"count":4}
         Producing record: alice	{"count":5}
         Producing record: alice	{"count":6}
         Producing record: alice	{"count":7}
         Producing record: alice	{"count":8}
         Producing record: alice	{"count":9}
         Produced record to topic demo-topic-1 partition [3] @ offset 0
         Produced record to topic demo-topic-1 partition [3] @ offset 1
         Produced record to topic demo-topic-1 partition [3] @ offset 2
         Produced record to topic demo-topic-1 partition [3] @ offset 3
         Produced record to topic demo-topic-1 partition [3] @ offset 4
         Produced record to topic demo-topic-1 partition [3] @ offset 5
         Produced record to topic demo-topic-1 partition [3] @ offset 6
         Produced record to topic demo-topic-1 partition [3] @ offset 7
         Produced record to topic demo-topic-1 partition [3] @ offset 8
         Produced record to topic demo-topic-1 partition [3] @ offset 9
         10 messages were produced to topic demo-topic-1

#. Run the following commands to delete the ACLs:

   .. code-block:: bash

      ccloud kafka acl delete --allow --service-account 104349 --operation CREATE --topic demo-topic-1
      ccloud kafka acl delete --allow --service-account 104349 --operation WRITE --topic demo-topic-1

   You should see a ``Deleted ACLs`` message.

#. Create a new Kafka topic ``demo-topic-2``:

   .. code-block:: bash

      ccloud kafka topic create demo-topic-2

   You should see a ``Created topic "demo-topic-2"`` message.



Run a Java producer to showcase a prefixed ACL
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Run the following command to create ACLs for the producer using a prefix:

   .. code-block:: bash

      ccloud kafka acl create --allow --service-account 104349 --operation CREATE --topic demo-topic --prefix
      ccloud kafka acl create --allow --service-account 104349 --operation WRITE --topic demo-topic --prefix

#. Verify you see the following output:

   .. code-block:: text

      ServiceAccountId | Permission | Operation | Resource |    Name    |   Type
      +------------------+------------+-----------+----------+------------+----------+
      User:104349      | ALLOW      | CREATE    | TOPIC    | demo-topic | PREFIXED

      ServiceAccountId | Permission | Operation | Resource |    Name    |   Type
      +------------------+------------+-----------+----------+------------+----------+
      User:104349      | ALLOW      | WRITE     | TOPIC    | demo-topic | PREFIXED

#. Verify the ACLs were configured by running the following command:

   .. code-block:: bash

      ccloud kafka acl list --service-account 104349

   .. code-block:: text

         ServiceAccountId | Permission | Operation | Resource |    Name    |   Type
       +------------------+------------+-----------+----------+------------+----------+
         User:104349      | ALLOW      | WRITE     | TOPIC    | demo-topic | PREFIXED
         User:104349      | ALLOW      | CREATE    | TOPIC    | demo-topic | PREFIXED

#. Run the Java producer to ``demo-topic-2`` to prefix the ACLs:

   .. code-block:: bash

      mvn -q -f ../../clients/cloud/java/pom.xml exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" -Dexec.args="/tmp/client.config demo-topic-2" -Dlog4j.configuration=file:log4j.properties > /tmp/log.3 2>&1

#. Verify you see the ``10 messages were produced to topic`` message in the logs as
   shown in the following example:

   .. code-block:: text

      PASS
      [2020-08-29 13:52:39,012] WARN The configuration 'sasl.jaas.config' was supplied but isn't a known config. (org.apache.kafka.clients.admin.AdminClientConfig)
      [2020-08-29 13:52:39,013] WARN The configuration 'ssl.endpoint.identification.algorithm' was supplied but isn't a known config. (org.apache.kafka.clients.admin.AdminClientConfig)
      Producing record: alice	{"count":0}
      Producing record: alice	{"count":1}
      Producing record: alice	{"count":2}
      Producing record: alice	{"count":3}
      Producing record: alice	{"count":4}
      Producing record: alice	{"count":5}
      Producing record: alice	{"count":6}
      Producing record: alice	{"count":7}
      Producing record: alice	{"count":8}
      Producing record: alice	{"count":9}
      Produced record to topic demo-topic-2 partition [3] @ offset 0
      Produced record to topic demo-topic-2 partition [3] @ offset 1
      Produced record to topic demo-topic-2 partition [3] @ offset 2
      Produced record to topic demo-topic-2 partition [3] @ offset 3
      Produced record to topic demo-topic-2 partition [3] @ offset 4
      Produced record to topic demo-topic-2 partition [3] @ offset 5
      Produced record to topic demo-topic-2 partition [3] @ offset 6
      Produced record to topic demo-topic-2 partition [3] @ offset 7
      Produced record to topic demo-topic-2 partition [3] @ offset 8
      Produced record to topic demo-topic-2 partition [3] @ offset 9
      10 messages were produced to topic demo-topic-2

#. Run the following commands to delete ACLs:

   .. code-block:: bash

      ccloud kafka acl delete --allow --service-account 104349 --operation CREATE --topic demo-topic --prefix
      ccloud kafka acl delete --allow --service-account 104349 --operation WRITE --topic demo-topic --prefix

   You should see a ``Deleted ACLs`` message.

#. Create a new Kafka topic ``demo-topic-3``:

   .. code-block:: bash

      ccloud kafka topic create demo-topic-3

   You should see a ``Created topic "demo-topic-3"`` message.


Run Connect and kafka-connect-datagen connector with permissions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Run the following command to create an ACL for Connect:

   .. code-block:: bash

      ccloud kafka acl create --allow --service-account 104349 --operation CREATE --topic '*'

   You should see:

   .. code-block:: text

         ServiceAccountId | Permission | Operation | Resource | Name |  Type
       +------------------+------------+-----------+----------+------+---------+
         User:104349      | ALLOW      | CREATE    | TOPIC    | *    | LITERAL


#. Run the following command to allow user ``104349`` to write to any topic
   in the ACL you created previously:

   .. code-block:: bash

      ccloud kafka acl create --allow --service-account 104349 --operation WRITE --topic '*'

   You should see the following output:

   .. code-block:: text

         ServiceAccountId | Permission | Operation | Resource | Name |  Type
       +------------------+------------+-----------+----------+------+---------+
         User:104349      | ALLOW      | WRITE     | TOPIC    | *    | LITERAL


#. Run the following command to allow user ``104349`` to read from any topic
   in the ACL:

   .. code-block:: bash

      ccloud kafka acl create --allow --service-account 104349 --operation READ --topic '*'

   .. code-block:: text

         ServiceAccountId | Permission | Operation | Resource | Name |  Type
       +------------------+------------+-----------+----------+------+---------+
         User:104349      | ALLOW      | READ      | TOPIC    | *    | LITERAL


#. Run the following command to allow user ``104349`` to read from any topic
   in the ACL:

   .. code-block:: bash

       ccloud kafka acl create --allow --service-account 104349 --operation READ --consumer-group connect

   .. code-block:: text

         ServiceAccountId | Permission | Operation | Resource |  Name   |  Type
         +------------------+------------+-----------+----------+---------+---------+
         User:104349      | ALLOW      | READ      | GROUP    | connect | LITERAL

#. Verify the ACLs were configured by running the following command:

   .. code-block:: bash

      ccloud kafka acl list --service-account 104349

   .. code-block:: text

         ServiceAccountId | Permission | Operation | Resource |  Name   |  Type
       +------------------+------------+-----------+----------+---------+---------+
         User:104349      | ALLOW      | WRITE     | TOPIC    | *       | LITERAL
         User:104349      | ALLOW      | CREATE    | TOPIC    | *       | LITERAL
         User:104349      | ALLOW      | READ      | TOPIC    | *       | LITERAL
         User:104349      | ALLOW      | READ      | GROUP    | connect | LITERAL

#. Generate environment variables with |ccloud| connection information for
   |kconnect| to use:

   .. code-block:: text

      ../../ccloud/ccloud-generate-cp-configs.sh /tmp/client.config &>/dev/null
      source delta_configs/env.delta

# Run a |kconnect| container with the kafka-connect-datagen plugin:

  .. code-block:: bash

     docker-compose up -d

  You should see the following output:

  .. code-block:: text

      Creating connect-cloud ... done
      Waiting up to 60 seconds for Docker container for connect to be up
      ............

#. Post the configuration for the kafka-connect-datagen connector that produces
   pageviews data to |ccloud| topic ``demo-topic-3``:

   .. code-block:: text

         DATA=$( cat << EOF
         {
            "name": "$CONNECTOR",
            "config": {
              "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
              "kafka.topic": "$TOPIC3",
              "quickstart": "pageviews",
              "key.converter": "org.apache.kafka.connect.storage.StringConverter",
              "value.converter": "org.apache.kafka.connect.json.JsonConverter",
              "value.converter.schemas.enable": "false",
              "max.interval": 5000,
              "iterations": 1000,
              "tasks.max": "1"
            }
         }
         EOF
         )
         curl --silent --output /dev/null -X POST -H "Content-Type: application/json" --data "${DATA}" http://localhost:8083/connectors


#. Wait 20 seconds for kafka-connect-datagen to start producing messages.

#. Run the following command to verify connector is running:

   .. code-block:: bash

      curl --silent http://localhost:8083/connectors/datagen-demo-topic-3/status | jq -r '.'

   .. code-block:: text

      {
         "name": "datagen-demo-topic-3",
         "connector": {
           "state": "RUNNING",
           "worker_id": "connect:8083"
         },
         "tasks": [
           {
             "id": 0,
             "state": "RUNNING",
             "worker_id": "connect:8083"
           }
         ],
         "type": "source"
      }


Run a Java consumer to showcase a Wildcard ACL
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Create ACLs for the consumer using a wildcard by running the following
   commands:

   .. code-block:: bash

      ccloud kafka acl create --allow --service-account 104349 --operation READ --consumer-group demo-beginner-cloud-1
      ccloud kafka acl create --allow --service-account 104349 --operation READ --topic '*'

   .. code-block:: text

        ServiceAccountId | Permission | Operation | Resource |         Name          |  Type
      +------------------+------------+-----------+----------+-----------------------+---------+
        User:104349      | ALLOW      | READ      | GROUP    | demo-beginner-cloud-1 | LITERAL

        ServiceAccountId | Permission | Operation | Resource | Name |  Type
      +------------------+------------+-----------+----------+------+---------+
        User:104349      | ALLOW      | READ      | TOPIC    | *    | LITERAL


#. Verify the ACLs were configured by running the following command:

   .. code-block:: bash

      ccloud kafka acl list --service-account 104349

   You should see:

   .. code-block:: text

         ServiceAccountId | Permission | Operation | Resource |         Name          |  Type
       +------------------+------------+-----------+----------+-----------------------+---------+
         User:104349      | ALLOW      | READ      | GROUP    | connect               | LITERAL
         User:104349      | ALLOW      | CREATE    | TOPIC    | *                     | LITERAL
         User:104349      | ALLOW      | WRITE     | TOPIC    | *                     | LITERAL
         User:104349      | ALLOW      | READ      | TOPIC    | *                     | LITERAL
         User:104349      | ALLOW      | READ      | GROUP    | demo-beginner-cloud-1 | LITERAL


#. Run the Java consumer from ``demo-topic-3 (populated by kafka-connect-datagen)``:

   .. code-block:: bash

      mvn -q -f ../../clients/cloud/java/pom.xml exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ConsumerExamplePageviews" -Dexec.args="/tmp/client.config demo-topic-3" -Dlog4j.configuration=file:log4j.properties > /tmp/log.4 2>&1

#. Verify you see the ``Consumed record with`` message in the log file
   ``/tmp/log.4`` as shown in the following example:

   .. code-block:: text

      PASS
      Consumed record with key 1 and value {"viewtime":1,"userid":"User_6","pageid":"Page_82"}
      Consumed record with key 71 and value {"viewtime":71,"userid":"User_6","pageid":"Page_11"}
      Consumed record with key 51 and value {"viewtime":51,"userid":"User_7","pageid":"Page_24"}
      Consumed record with key 31 and value {"viewtime":31,"userid":"User_7","pageid":"Page_68"}
      Consumed record with key 81 and value {"viewtime":81,"userid":"User_5","pageid":"Page_25"}
      Consumed record with key 41 and value {"viewtime":41,"userid":"User_2","pageid":"Page_88"}
      Consumed record with key 91 and value {"viewtime":91,"userid":"User_2","pageid":"Page_74"}
      Consumed record with key 101 and value {"viewtime":101,"userid":"User_8","pageid":"Page_11"}
      Consumed record with key 111 and value {"viewtime":111,"userid":"User_1","pageid":"Page_34"}
      Consumed record with key 11 and value {"viewtime":11,"userid":"User_3","pageid":"Page_75"}
      Consumed record with key 21 and value {"viewtime":21,"userid":"User_8","pageid":"Page_81"}
      Consumed record with key 61 and value {"viewtime":61,"userid":"User_9","pageid":"Page_65"}
      Consumed record with key 121 and value {"viewtime":121,"userid":"User_3","pageid":"Page_51"}
      Consumed record with key 131 and value {"viewtime":131,"userid":"User_1","pageid":"Page_83"}
      Consumed record with key 141 and value {"viewtime":141,"userid":"User_8","pageid":"Page_77"}
      Consumed record with key 151 and value {"viewtime":151,"userid":"User_6","pageid":"Page_58"}
      Consumed record with key 161 and value {"viewtime":161,"userid":"User_2","pageid":"Page_15"}

# Delete the ACLs by running the following command:

  .. code-block:: bash

      ccloud kafka acl delete --allow --service-account 104349 --operation READ --consumer-group demo-beginner-cloud-1
      ccloud kafka acl delete --allow --service-account 104349 --operation READ --topic '*'


  You should see: ``Deleted ACLs.Deleted ACLs.``

#. Stop Docker:

   .. code-block:: bash

        docker-compose down

   You should see the following output:

   .. code-block:: text

      Stopping connect-cloud ... done
      Removing connect-cloud ... done
      Removing network beginner-cloud_default

#. Delete the ACLs:

   .. code-block:: bash

      ccloud kafka acl delete --allow --service-account 104349 --operation CREATE --topic '*'

   You should see:

   .. code-block:: text

      Deleted ACLs.ccloud kafka acl delete --allow --service-account 104349 --operation WRITE --topic '*'
      Deleted ACLs.ccloud kafka acl delete --allow --service-account 104349 --operation READ --topic '*'
      Deleted ACLs.ccloud kafka acl delete --allow --service-account 104349 --operation READ --consumer-group connect
      Deleted ACLs.


Delete the API key, service account, Kafka topics, Kafka cluster, environment, and the log files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Run the following command to delete the service-account:

   .. code-block:: bash

      ccloud service-account delete 104349

#. Complete the following steps to delete all the Kafka topics:

   a. Delete ``demo-topic-1``:

      .. code-block:: bash

         ccloud kafka topic delete demo-topic-1

      You should see: ``Deleted topic "demo-topic-1"``.

   b. Delete ``demo-topic-2``:

      .. code-block:: bash

         ccloud kafka topic delete demo-topic-2

      You should see: ``Deleted topic "demo-topic-2"``.

   c. Delete ``demo-topic-3``:

      .. code-block:: bash

         ccloud kafka topic delete demo-topic-3

      You should see: ``Deleted topic "demo-topic-3"``.

   d. Delete ``connect-configs``:

      .. code-block:: bash

         ccloud kafka topic delete connect-configs

      You should see: ``Deleted topic "connect-configs"``.

   e. Delete ``connect-offsets``:

      .. code-block:: bash

         ccloud kafka topic delete connect-offsets

      You should see: ``Deleted topic "connect-offsets"``.

   f. Delete ``connect-status``:

      .. code-block:: bash

         ccloud kafka topic delete connect-status

      You should see: ``Deleted topic "connect-status"``.

#. Run the following commands to delete the API keys:

   .. code-block:: bash

      ccloud api-key delete ESN5FSNDHOFFSUEV
      ccloud api-key delete QX7X4VA4DFJTTOIA

#. Delete the Kafka cluster:

   .. code-block:: bash

      ccloud kafka cluster delete lkc-x6m01

#. Delete the environment:

   .. code-block:: bash

      ccloud environment delete env-5qz2q

   You should see: ``Deleted environment "env-5qz2q"``.


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

- See other :ref:`ccloud-demos-overview`.


