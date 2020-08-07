Confluent Cloud CLI
-------------------

In this tutorial, you will run a Conlfuent Cloud CLI client application that produces
messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

-  Local install of :ref:`Confluent Cloud CLI <ccloud-install-cli>` v1.13.0 or later.

-  You must have access to a `Confluent
   Cloud <https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__
   cluster

   -  The first 20 users to sign up for `Confluent
      Cloud <https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__
      and use promo code ``C50INTEG`` will receive an additional $50
      free usage
      (`details <https://www.confluent.io/confluent-cloud-promo-disclaimer/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__).

Example 1: Hello World!
=======================

In this example, the producer writes Kafka data to a topic in your Kafka
cluster. Each record has a key representing a username (e.g. ``alice``)
and a value of a count, formatted as json (e.g. ``{"count": 0}``). The
consumer reads the same topic.

1. Create the topic in Confluent Cloud

.. code:: bash

   $ ccloud kafka topic create test1

2. Run the :ref:`Confluent Cloud CLI producer <ccloud_kafka_topic_produce>`, writing messages to topic
   ``test1``, passing in additional arguments:

-  ``--parse-key --delimiter ,``: pass key and value, separated by a
   comma

.. code:: bash

   $ ccloud kafka topic produce test1 --parse-key --delimiter ,

Type a few messages, using a ``,`` as the separator between the message
key and value:

.. code:: bash

   alice,{"count":0}
   alice,{"count":1}
   alice,{"count":2}

When you are done, press ``<ctrl>-c``.

2. Run the :ref:`Confluent Confluent CLI consumer <ccloud_kafka_topic_consume>`,
   reading messages from topic ``test1``, passing in additional
   arguments:

-  ``-b``: print all messages from the beginning of the topic
-  ``--print-key``: print key and value (by default, it only prints
   value)

.. code:: bash

   $ ccloud kafka topic consume test1 -b --print-key

You should see the messages you typed in the previous step.

.. code:: bash

   alice   {"count":0}
   alice   {"count":1}
   alice   {"count":2}

When you are done, press ``<ctrl>-c``.

3. To demo the above commands, you may also run the provided script
   `ccloud-example.sh <ccloud-example.sh>`__.

Example 2: Avro And Confluent Cloud Schema Registry
===================================================

This example is similar to the previous example, except the value is
formatted as Avro and integrates with the Confluent Cloud Schema
Registry. Before using Confluent Cloud Schema Registry, check its
`availability and
limits <https://docs.confluent.io/current/cloud/limits.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__.
Note that your VPC must be able to connect to the Confluent Cloud Schema
Registry public internet endpoint.

1. As described in the `Confluent Cloud
   quickstart <https://docs.confluent.io/current/quickstart/cloud-quickstart/schema-registry.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__,
   in the Confluent Cloud GUI, enable Confluent Cloud Schema Registry
   and create an API key and secret to connect to it.

2. Create the topic in Confluent Cloud

.. code:: bash

   $ ccloud kafka topic create test2

3. Create a file that has the schema of your message payload.

.. code:: bash

   echo '{"type":"record","name":"myrecord","fields":[{"name":"count","type":"int"}]}' > schema.json

4. Run the :ref:`Confluent Cloud CLI producer <ccloud_kafka_topic_produce>`
   writing messages to topic ``test2``, passing in additional arguments:

-  ``--value-format avro``: use Avro data format for the value part of
   the message
-  ``--schema``: the path to the schema file
-  ``--parse-key --delimiter ,``: pass key and value, separated by a
   comma

Note: the first time you run this, you will need to provide user
credentials for Confluent Cloud Schema Registry.

.. code:: bash

   $ ccloud kafka topic produce test2 --value-format avro --schema schema.json --parse-key --delimiter ,

Type a few messages, using a ``,`` as the separator between the message
key and value:

.. code:: bash

   alice,{"count":3}
   alice,{"count":4}
   alice,{"count":5}

When you are done, press ``<ctrl>-c``.

5. Run the :ref:`Confluent Confluent CLI consumer <ccloud_kafka_topic_consume>`
   reading messages from topic ``test2``, passing in additional
   arguments:

-  ``-b``: print all messages from the beginning of the topic
-  ``--value-format avro``: use Avro data format for the value part of
   the message
-  ``--print-key``: print key and value (by default, it only prints
   value)

.. code:: bash

   $ ccloud kafka topic consume test2 -b --value-format avro --print-key

You should see the messages you typed in the previous step.

.. code:: bash

   alice   {"count":3}
   alice   {"count":4}
   alice   {"count":5}

When you are done, press ``<ctrl>-c``.

6. To demo the above commands, you may also run the provided script
   `ccloud-ccsr-example.sh <ccloud-ccsr-example.sh>`__.

7. View the schema information registered in Confluent Cloud Schema
   Registry. In the output below, substitute values for
   ``{{ SR_API_KEY }}``, ``{{ SR_API_SECRET }}``, and
   ``{{ SR_ENDPOINT }}``.

   ::

      # View the list of registered subjects
      $ curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects
      ["test2-value"]

      # View the schema information for subject `test2-value`
      $ curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects/test2-value/versions/1
      {"subject":"test2-value","version":1,"id":100001,"schema":"{\"type\":\"record\",\"name\":\"myrecord\",\"fields\":[{\"name\":\"count\",\"type\":\"int\"}]}"}
