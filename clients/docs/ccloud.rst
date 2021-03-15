.. _client-examples-ccloud:

Confluent Cloud CLI: Command Example for |ak-tm|
================================================

In this tutorial, you will use the |ccloud| CLI to
produces messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

Client
~~~~~~

-  Local install of `Confluent Cloud CLI <https://docs.confluent.io/ccloud-cli/current/install.html>`__ v1.25.0 or later.
-  .. include:: ../../ccloud/docs/includes/prereq_timeout.rst


Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for |ccloud| CLI.

   .. code-block:: bash

      cd clients/cloud/ccloud/

#. Log in to |ccloud| with the command ``ccloud login``, and use your |ccloud| username and password. The ``--save`` argument saves your |ccloud| user login credentials or refresh token (in the case of SSO) to the local ``netrc`` file.

   .. code:: bash

      ccloud login --save


Basic Producer and Consumer
----------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Create the topic in |ccloud|.

   .. code-block:: bash

      ccloud kafka topic create test1

#. Run the `Confluent Cloud CLI producer <https://docs.confluent.io/ccloud-cli/current/command-reference/kafka/topic/ccloud_kafka_topic_produce.html>`__,
   writing messages to topic ``test1``, passing in arguments for:

   -  ``--parse-key --delimiter ,``: pass key and value, separated by a comma

   .. code-block:: bash

      ccloud kafka topic produce test1 --parse-key --delimiter ,

#. Type a few messages, using a ``,`` as the separator between the message key
   and value:

   .. code-block:: text

      alice,{"count":0}
      alice,{"count":1}
      alice,{"count":2}

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`producer code|clients/cloud/ccloud/ccloud-example.sh`.


Consume Records
~~~~~~~~~~~~~~~

#. Run the `Confluent Cloud CLI consumer <https://docs.confluent.io/ccloud-cli/current/command-reference/kafka/topic/ccloud_kafka_topic_consume.html>`__,
   reading messages from topic ``test1``, passing in arguments for:

   -  ``-b``: print all messages from the beginning of the topic -
   - ``--print-key``: print key and value (by default, it only prints value)

   .. code-block:: bash

      ccloud kafka topic consume test1 -b --print-key

#. Verify that the consumer received all the messages. You should see:

   .. code-block:: text

       alice   {"count":0}
       alice   {"count":1}
       alice   {"count":2}

#. When you are done, press ``CTRL-C``.

#. View the :devx-examples:`consumer code|clients/cloud/ccloud/ccloud-example.sh`.


Avro And Confluent Cloud Schema Registry
----------------------------------------

.. include:: includes/schema-registry-scenario-explain.rst

#. .. include:: includes/client-example-schema-registry-1.rst

#. .. include:: includes/client-example-vpc.rst


Produce Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Create the topic in |ccloud|.

   .. code-block:: bash

      ccloud kafka topic create test2

#. Create a file, for example ``schema.json``, that has the schema of your message payload.

   .. code-block:: text

      echo '{"type":"record","name":"myrecord","fields":[{"name":"count","type":"int"}]}' > schema.json

#. Run the `Confluent Cloud CLI producer <https://docs.confluent.io/ccloud-cli/current/command-reference/kafka/topic/ccloud_kafka_topic_produce.html>`__
   writing messages to topic ``test2``, passing in arguments for:

   -  ``--value-format avro``: use Avro data format for the value part of the
      message
   -  ``--schema``: the path to the schema file
   -  ``--parse-key --delimiter ,``: pass key and value, separated by a comma

   .. code-block:: bash

      ccloud kafka topic produce test2 --value-format avro --schema schema.json --parse-key --delimiter ,

   .. note::

      The first time you run this command, you must provide user credentials for |ccloud| |sr|.

#. Type a few messages, using a ``,`` as the separator between the message key and value:

   .. code-block:: text

      alice,{"count":3}
      alice,{"count":4}
      alice,{"count":5}

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`producer Avro code|clients/cloud/ccloud/ccloud-ccsr-example.sh`.


Consume Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Run the `Confluent Confluent CLI consumer <https://docs.confluent.io/ccloud-cli/current/command-reference/kafka/topic/ccloud_kafka_topic_consume.html>`__
   reading messages from topic ``test2``, passing in arguments for:

   -  ``-b``: print all messages from the beginning of the topic
   -  ``--value-format avro``: use Avro data format for the value part of the
      message
   -  ``--print-key``: print key and value (by default, it only prints value)

   .. code-block:: bash

      ccloud kafka topic consume test2 -b --value-format avro --print-key

#. Verify that the consumer received all the messages. You should see:

   .. code-block:: text

       alice   {"count":3}
       alice   {"count":4}
       alice   {"count":5}

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`consumer Avro code|clients/cloud/ccloud/ccloud-ccsr-example.sh`.
