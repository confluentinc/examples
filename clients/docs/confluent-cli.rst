.. _client-examples-confluent-cli:

Confluent CLI: Command Example for |ak-tm|
==========================================

In this tutorial, you will use the |confluent-cli| to produce messages to and
consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst

.. note::

   The Confluent CLI is meant for development purposes only and isn't suitable
   for a production environment.

Prerequisites
-------------

Client
~~~~~~

- `Download <https://www.confluent.io/download/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__ |cp| |release|, which includes the |confluent-cli|.


Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for Confluent CLI.

   .. code-block:: bash

      cd clients/cloud/confluent-cli/

#. .. include:: includes/client-example-create-file-java.rst


Basic Producer and Consumer
----------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Create the |ak| topic. 

   .. code-block:: text

      kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` --command-config $HOME/.confluent/java.config --topic test1 --create --replication-factor 3 --partitions 6

#. Run the `Confluent CLI
   producer <https://docs.confluent.io/confluent-cli/current/command-reference/local/services/kafka/confluent_local_services_kafka_produce.html>`__,
   writing messages to topic ``test1``, passing in arguments for:

   -  ``--cloud``: write messages to a |ccloud| cluster
   -  ``--config``: file with |ccloud| connection info
   -  ``--property parse.key=true --property key.separator=,``: pass key and
      value, separated by a comma

   .. code-block:: text

      confluent local services kafka produce test1 --cloud --config $HOME/.confluent/java.config --property parse.key=true --property key.separator=,

#. At the ``>`` prompt, type a few messages, using a ``,`` as the separator
   between the message key and value:

   .. code-block:: text

       alice,{"count":0}
       alice,{"count":1}
       alice,{"count":2}

#. When you are done, press ``Ctrl-D``.

#. View the :devx-examples:`producer code|clients/cloud/confluent-cli/confluent-cli-example.sh`.


Consume Records
~~~~~~~~~~~~~~~

#. Run the `Confluent CLI
   consumer
   <https://docs.confluent.io/confluent-cli/current/command-reference/local/services/kafka/confluent_local_services_kafka_consume.html>`__,
   reading messages from topic ``test1``, passing in additional arguments:

   -  ``--cloud``: write messages to a |ccloud| cluster
   -  ``--config``: file with |ccloud| connection info
   -  ``--property print.key=true``: print key and value (by default, it only
      prints value)
   -  ``--from-beginning``: print all messages from the beginning of the topic

   .. code-block:: bash

      confluent local services kafka consume test1 --cloud --config $HOME/.confluent/java.config --property print.key=true --from-beginning

#. Verify the consumer received all the messages. You should see:

   .. code-block:: text

      alice   {"count":0}
      alice   {"count":1}
      alice   {"count":2}

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`consumer code|clients/cloud/confluent-cli/confluent-cli-example.sh`.


Avro And Confluent Cloud Schema Registry
----------------------------------------

.. include:: includes/schema-registry-scenario-explain.rst

#. .. include:: includes/client-example-schema-registry-1.rst

#. .. include:: includes/client-example-vpc.rst

#. .. include:: includes/schema-registry-java.rst

#. .. include:: includes/client-example-schema-registry-2-java.rst


Produce Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Verify your |ccloud| |sr| credentials work from your host. In the output
   below, substitute your values for ``<SR API KEY>``, ``<SR API SECRET>``, and
   ``<SR ENDPOINT>``.

   .. code-block:: text

      # View the list of registered subjects
      curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects

      # Same as above, as a single bash command to parse the values out of $HOME/.confluent/java.config
      curl -u $(grep "^schema.registry.basic.auth.user.info" $HOME/.confluent/java.config | cut -d'=' -f2) $(grep "^schema.registry.url" $HOME/.confluent/java.config | cut -d'=' -f2)/subjects

#. View your local |ccloud| configuration file (``$HOME/.confluent/java.config``):

   .. code-block:: bash

      cat $HOME/.confluent/java.config

#. In the configuration file, substitute values for ``<SR API KEY>``,
   ``<SR API SECRET>``, and ``<SR ENDPOINT>``  as displayed in the following
   example:

   .. code-block:: bash

      ...
      basic.auth.credentials.source=USER_INFO
      schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
      schema.registry.url=https://<SR ENDPOINT>
      ...

#. Create the |ak| topic. 

   .. code-block:: bash

      kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` --command-config $HOME/.confluent/java.config --topic test2 --create --replication-factor 3 --partitions 6

#. Run the `Confluent CLI
   producer <https://docs.confluent.io/confluent-cli/current/command-reference/local/services/kafka/confluent_local_services_kafka_produce.html>`__,
   writing messages to topic ``test2``, passing in arguments for:

   -  ``--value-format avro``: use Avro data format for the value part of the
      message
   -  ``--property value.schema``: define the schema
   -  ``--property schema.registry.url``: connect to the |ccloud| |sr| endpoint
      ``http://<SR ENDPOINT>``
   -  ``--property basic.auth.credentials.source``: specify ``USER_INFO``
   -  ``--property schema.registry.basic.auth.user.info``: ``<SR API KEY>:<SR API SECRET>``

   .. important::

      You must pass in the additional |sr| parameters as properties instead of a
      properties file due to
      https://github.com/confluentinc/schema-registry/issues/1052.

   .. code-block:: bash

      confluent local services kafka produce test2 --cloud --config $HOME/.confluent/java.config --value-format avro --property value.schema='{"type":"record","name":"myrecord","fields":[{"name":"count","type":"int"}]}' --property schema.registry.url=https://<SR ENDPOINT> --property basic.auth.credentials.source=USER_INFO --property schema.registry.basic.auth.user.info='<SR API KEY>:<SR API SECRET>'

#. At the ``>`` prompt, type the following messages:

   .. code-block:: bash

      {"count":0}
      {"count":1}
      {"count":2}

#. When you are done, press ``Ctrl-D``.

#. View the :devx-examples:`producer Avro code|clients/cloud/confluent-cli/confluent-cli-ccsr-example.sh`.


Consume Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Run the `Confluent CLI
   consumer
   <https://docs.confluent.io/confluent-cli/current/command-reference/local/services/kafka/confluent_local_services_kafka_consume.html>`__,
   reading messages from topic ``test2``, passing in arguments for:

   -  ``--value-format avro``: use Avro data format for the value part of the
      message
   -  ``--property schema.registry.url``: connect to the |ccloud| |sr| endpoint
      ``http://<SR ENDPOINT>``
   -  ``--property basic.auth.credentials.source``: specify ``USER_INFO``
   -  ``--property schema.registry.basic.auth.user.info``: ``<SR API KEY>:<SR API SECRET>``

   .. important::

      You must pass in the additional |sr| parameters as properties instead of a
      properties file due to
      https://github.com/confluentinc/schema-registry/issues/1052.

   .. code-block:: bash

      confluent local services kafka consume test2 --cloud --config $HOME/.confluent/java.config --value-format avro --property schema.registry.url=https://<SR ENDPOINT> --property basic.auth.credentials.source=USER_INFO --property schema.registry.basic.auth.user.info='<SR API KEY>:<SR API SECRET>' --from-beginning

#. Verify the consumer received all the messages. You should see:

   .. code-block:: text

      {"count":0}
      {"count":1}
      {"count":2}

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`consumer Avro code|clients/cloud/confluent-cli/confluent-cli-ccsr-example.sh`.
