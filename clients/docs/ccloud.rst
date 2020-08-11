.. _client-examples-ccloud:

Confluent Cloud CLI
===================

In this tutorial, you will run a |confluent-cli| client application that
produces messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

Client
~~~~~~

-  Local install of :ref:`Confluent Cloud CLI <ccloud-install-cli>` v1.13.0 or later.

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for |confluent-cli|.

   .. code-block:: bash

      cd clients/cloud/ccloud/

#. .. include:: includes/client-example-create-file.rst

#. .. include:: includes/client-example-create-file-java.rst


Basic Producer and Consumer
----------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Create the topic in |ccloud|.

   .. code-block:: bash

      ccloud kafka topic create test1

#. Run the :ref:`Confluent Cloud CLI producer <ccloud_kafka_topic_produce>`,
   writing messages to topic ``test1``, passing in arguments for:

   -  ``--parse-key --delimiter ,``: pass key and value, separated by a comma

   .. code-block:: bash

      ccloud kafka topic produce test1 --parse-key --delimiter ,

#. Type a few messages, using a ``,`` as the separator between the message key
   and value:

   .. code-block:: bash

      alice,{"count":0}
      alice,{"count":1}
      alice,{"count":2}

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`producer code|clients/cloud/ccloud/ccloud-example.sh`.


Consume Records
~~~~~~~~~~~~~~~

#. Run the :ref:`Confluent Cloud CLI consumer <ccloud_kafka_topic_consume>`,
   reading messages from topic ``test1``, passing in arguments for:

   -  ``-b``: print all messages from the beginning of the topic -
   - ``--print-key``: print key and value (by default, it only prints value)

   .. code-block:: bash

      ccloud kafka topic consume test1 -b --print-key

   You should see the messages you typed in the previous section:

   .. code-block:: bash

       alice   {"count":0}
       alice   {"count":1}
       alice   {"count":2}

#. When you are done, press ``CTRL-C``.

#. View the :devx-examples:`consumer code|clients/cloud/ccloud/ccloud-example.sh`.


Avro And Confluent Cloud Schema Registry
----------------------------------------

#. .. include:: includes/client-example-vpc.rst

#. .. include:: includes/client-example-schema-registry-1.rst

.. include:: includes/client-example-schema-registry-3.rst


Produce Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Create the topic in |ccloud|.

   .. code-block:: bash

      ccloud kafka topic create test2

#. Create a file that has the schema of your message payload.

   .. code-block:: bash

      echo '{"type":"record","name":"myrecord","fields":[{"name":"count","type":"int"}]}' > schema.json

#. Run the :ref:`Confluent Cloud CLI producer <ccloud_kafka_topic_produce>`
   writing messages to topic ``test2``, passing in arguments for:

   -  ``--value-format avro``: use Avro data format for the value part of the
      message
   -  ``--schema``: the path to the schema file
   -  ``--parse-key --delimiter ,``: pass key and value, separated by a comma

   .. code-block:: bash

      ccloud kafka topic produce test2 --value-format avro --schema schema.json --parse-key --delimiter ,

      .. note::

          The first time you run this command, you must provide user credentials
          for |ccloud| |sr|.

#. Type a few messages, using a ``,`` as the separator between the message key and value:

   .. code-block:: bash

      alice,{"count":3}
      alice,{"count":4}
      alice,{"count":5}

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`producer Avro code|clients/cloud/ccloud/ccloud-ccsr-example.sh`.


Consume Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Run the :ref:`Confluent Confluent CLI consumer <ccloud_kafka_topic_consume>`
   reading messages from topic ``test2``, passing in arguments for:

   -  ``-b``: print all messages from the beginning of the topic
   -  ``--value-format avro``: use Avro data format for the value part of the
      message
   -  ``--print-key``: print key and value (by default, it only prints value)

   .. code-block:: bash

      ccloud kafka topic consume test2 -b --value-format avro --print-key


   You should see the messages you typed in the previous section:

   .. code-block:: bash

       alice   {"count":3}
       alice   {"count":4}
       alice   {"count":5}

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`consumer Avro code|clients/cloud/ccloud/ccloud-ccsr-example.sh`.


Schema Evolution with Confluent Cloud Schema Registry
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

View the schema information registered in |ccloud| |sr|. In the output below,
substitute values for ``{{ SR_API_KEY }}``, ``{{SR_API_SECRET }}``, and
``{{SR_ENDPOINT }}``.

.. code-block:: text

      # View the list of registered subjects
      curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects
      ["test2-value"]

      # View the schema information for subject `test2-value`
      curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects/test2-value/versions/1
      {"subject":"test2-value","version":1,"id":100001,"schema":"{\"type\":\"record\",\"name\":\"myrecord\",\"fields\":[{\"name\":\"count\",\"type\":\"int\"}]}"}
