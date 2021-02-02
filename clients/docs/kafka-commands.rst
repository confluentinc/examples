.. _client-examples-kafka-commands:

|ak-tm| CLI : Command Example
=============================

In this tutorial, you will run |ak-tm| commands that produce messages to and
consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

Client
~~~~~~

-  `Download <https://www.confluent.io/download/>`__ |cp| |release|

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for |ak-tm| commands.

   .. code-block:: bash

      cd clients/cloud/kafka-commands/

#. .. include:: includes/client-example-create-file-java.rst


Basic Producer and Consumer
---------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Create the |ak| topic. 

   .. code-block:: bash

      kafka-topics \
         --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` \
         --command-config $HOME/.confluent/java.config \
         --topic test1 \
         --create \
         --replication-factor 3 \
         --partitions 6

#. Run the ``kafka-console-producer`` command, writing messages to topic
   ``test1``, passing in arguments for:

   -  ``--property parse.key=true --property key.separator=,``: pass key
      and value, separated by a comma

   .. code-block:: bash

      kafka-console-producer \
         --topic test1 \
         --broker-list `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` \
         --property parse.key=true \
         --property key.separator=, \
         --producer.config $HOME/.confluent/java.config

#. At the ``>`` prompt, type a few messages, using a ``,`` as the separator
   between the message key and value:

   .. code-block:: text

      alice,{"count":0}
      alice,{"count":1}
      alice,{"count":2}

#. When you are done, press ``CTRL-D``.

#. View the :devx-examples:`producer code|clients/cloud/kafka-commands/kafka-commands.sh`.


Consume Records
~~~~~~~~~~~~~~~

#. Run the ``kafka-console-consumer`` command, reading messages from topic
   ``test1``, passing in additional arguments for:

   -  ``--property print.key=true``: print key and value (by default, it only
      prints value)

   -  ``--from-beginning``: print all messages from the beginning of the topic

   .. code-block:: bash

      kafka-console-consumer \
         --topic test1 \
         --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` \
         --property print.key=true \
         --from-beginning \
         --consumer.config $HOME/.confluent/java.config

   You should see the messages you typed in step 3.

   .. code-block:: text

      alice   {"count":0}
      alice   {"count":1}
      alice   {"count":2}

#. When you are done, press ``CTRL-C``.

#. View the :devx-examples:`consumer code|clients/cloud/kafka-commands/kafka-commands.sh`.


Avro and Confluent Cloud Schema Registry
----------------------------------------

.. include:: includes/schema-registry-scenario-explain.rst

#. .. include:: includes/client-example-schema-registry-1.rst

#. .. include:: includes/client-example-vpc.rst

#. .. include:: includes/schema-registry-java.rst

#. .. include:: includes/client-example-schema-registry-2-java.rst


Produce Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Create the topic in |ccloud|.

   .. code-block:: bash

      kafka-topics \
         --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` \
         --command-config $HOME/.confluent/java.config \
         --topic test2 \
         --create \
         --replication-factor 3 \
         --partitions 6

#. Run the ``kafka-avro-console-producer`` command, writing messages to
   topic ``test2``, passing in arguments for:

   -  ``--property value.schema``: define the schema
   -  ``--property schema.registry.url``: connect to the |sr-ccloud| endpoint
      ``https://<SR ENDPOINT>``
   -  ``--property basic.auth.credentials.source``: specify ``USER_INFO``
   -  ``--property schema.registry.basic.auth.user.info``:
      ``<SR API KEY>:<SR API SECRET>``

   .. important::

      You must pass in the additional |sr| parameters as properties instead of a
      properties file due to
      https://github.com/confluentinc/schema-registry/issues/1052.

   .. code-block:: bash

      kafka-avro-console-producer \
         --topic test2 \
         --broker-list `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` \
         --producer.config $HOME/.confluent/java.config \
         --property value.schema='{"type":"record","name":"myrecord","fields":[{"name":"count","type":"int"}]}' \
         --property schema.registry.url=https://<SR ENDPOINT> \
         --property basic.auth.credentials.source=USER_INFO \
         --property schema.registry.basic.auth.user.info='<SR API KEY>:<SR API SECRET>'

      # Same as above, as a single bash command to parse the values out of $HOME/.confluent/java.config
      kafka-avro-console-producer \
         --topic test2 \
         --broker-list `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` \
         --producer.config $HOME/.confluent/java.config \
         --property value.schema='{"type":"record","name":"myrecord","fields":[{"name":"count","type":"int"}]}' \
         --property schema.registry.url=$(grep "^schema.registry.url" $HOME/.confluent/java.config | cut -d'=' -f2) \
         --property basic.auth.credentials.source=USER_INFO \
         --property schema.registry.basic.auth.user.info=$(grep "^schema.registry.basic.auth.user.info" $HOME/.confluent/java.config | cut -d'=' -f2)

#. At the ``>`` prompt, type a few messages:

   .. code-block:: text

      {"count":0}
      {"count":1}
      {"count":2}

#. When you are done, press ``CTRL-D``.

#. View the :devx-examples:`producer Avro code|clients/cloud/kafka-commands/kafka-commands-ccsr.sh`.


Consume Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Run the ``kafka-avro-console-consumer`` command, reading messages
   from topic ``test``, passing in arguments for: The additional |sr| parameters
   are required to be passed in as properties instead of a properties file due
   to https://github.com/confluentinc/schema-registry/issues/1052.

   -  ``--property schema.registry.url``: connect to the |sr-ccloud| endpoint
      ``https://<SR ENDPOINT>``
   -  ``--property basic.auth.credentials.source``: specify ``USER_INFO``
   -  ``--property schema.registry.basic.auth.user.info``:
      ``<SR API KEY>:<SR API SECRET>``

   .. important::

      You must pass in the additional |sr| parameters as properties instead of a
      properties file due to
      https://github.com/confluentinc/schema-registry/issues/1052.

   .. code-block:: bash

      kafka-avro-console-consumer \
         --topic test2 \
         --from-beginning \
         --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` \
         --consumer.config $HOME/.confluent/java.config \
         --property schema.registry.url=https://<SR ENDPOINT> \
         --property basic.auth.credentials.source=USER_INFO \
         --property schema.registry.basic.auth.user.info='<SR API KEY>:<SR API SECRET>'

      Same as above, as a single bash command to parse the values out of $HOME/.confluent/java.config
      kafka-avro-console-consumer \
         --topic test2 \
         --from-beginning \
         --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` \
         --consumer.config $HOME/.confluent/java.config \
         --property schema.registry.url=$(grep "^schema.registry.url" $HOME/.confluent/java.config | cut -d'=' -f2) \
         --property basic.auth.credentials.source=USER_INFO \
         --property schema.registry.basic.auth.user.info=$(grep "^schema.registry.basic.auth.user.info" $HOME/.confluent/java.config | cut -d'=' -f2)

   You should see the messages you typed earlier.

   .. code-block:: text

      {"count":0}
      {"count":1}
      {"count":2}

#. When you are done, press ``CTRL-C``.

#. View the :devx-examples:`consumer Avro code|clients/cloud/kafka-commands/kafka-commands-ccsr.sh`.
