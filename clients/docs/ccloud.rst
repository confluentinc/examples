.. _client-examples-ccloud:

Confluent Cloud CLI
-------------------

In this tutorial, you will run a Confluent Cloud CLI client application that produces
messages to and consumes messages from an |ak-tm| cluster.

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

#. Clone the `confluentinc/examples GitHub repository
   <https://github.com/confluentinc/examples>`__ and check out the
   :litwithvars:`|release|-post` branch.

   .. codewithvars:: bash

      git clone https://github.com/confluentinc/examples
      cd examples
      git checkout |release|-post

#. Change directory to the example for Confluent Cloud CLI.

   .. code-block:: bash

      cd clients/cloud/ccloud/

#. .. include:: includes/client-example-create-file.rst


Basic Producer and Consumer
----------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

.. Should steps 1 through 3 below be under this  "Produce Records" section or before it?

#. Create the topic in Confluent Cloud.

   .. code:: bash

      ccloud kafka topic create test1

#. Run the :ref:`Confluent Cloud CLI producer <ccloud_kafka_topic_produce>`,
   writing messages to topic ``test1``, passing in additional arguments:

   -  ``--parse-key --delimiter ,``: pass key and value, separated by a comma

   .. code-block:: bash

      ccloud kafka topic produce test1 --parse-key --delimiter ,

.. Is there any output the user should verfiy when running the previous command or expected output they should see?

#. Type a few messages, using a ``,`` as the separator between the message key
   and value:

   .. code-block:: bash

      alice,{"count":0}
      alice,{"count":1}
      alice,{"count":2}

#. When you are done, press ``Ctrl-C``.

.. Is there a source code link for this one? I only saw two .sh files in the ccloud directory, but we have
   basic consumer/producer and then Avro consumer/producer. So assuming we'll need 4 source code links in total for this page?

Consume Records
~~~~~~~~~~~~~~~

#. Run the :ref:`Confluent Confluent CLI consumer <ccloud_kafka_topic_consume>`,
   reading messages from topic ``test1``, passing in the following arguments:

   -  ``-b``: print all messages from the beginning of the topic -
   - ``--print-key``: print key and value (by default, it only prints value)

   .. code:: bash

      ccloud kafka topic consume test1 -b --print-key

   You should see the messages you typed in the previous step.

   .. code:: bash

       alice   {"count":0}
       alice   {"count":1}
       alice   {"count":2}

#. When you are done, press ``CTRL-C``.

.. Not sure the correct source code link. I only saw two .sh files in the ccloud directory, but we have
   basic consumer/producer and then Avro consumer/producer. So assuming we'll need 4 source code links in total for this page?

#. View the :devx-examples:`consumer code|clients/cloud/java/src/main/java/io/confluent/examples/clients/cloud/ccloud/ccloud-example.sh`.


Avro And Confluent Cloud Schema Registry
----------------------------------------

.. include:: includes/client-example-schema-registry-3.rst


Produce Avro Records
~~~~~~~~~~~~~~~~~~~~

.. Should steps 1 through 3 below be under this  "Produce Avro Records" section or before it?

#. As described in the `Confluent Cloud
   quickstart <https://docs.confluent.io/current/quickstart/cloud-quickstart/schema-registry.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__,
   in the Confluent Cloud GUI, enable Confluent Cloud Schema Registry
   and create an API key and secret to connect to it.

#. Create the topic in Confluent Cloud.

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

.. should the user verify anything after running the previous command or is there specific output they should see after running the command

      .. note::

          The first time you run this command, you must provide user
          credentials for Confluent Cloud Schema Registry.

.. Is there a page where we can direct users to for help in providing their credentials for Confluent Cloud Schema Registry?

#. Type a few messages, using a ``,`` as the separator between the message key and value:

   .. code-block:: bash

      alice,{"count":3}
      alice,{"count":4}
      alice,{"count":5}

#. When you are done, press ``Ctrl-C``.

.. Not sure the correct source code link for this one. I only saw two .sh files in the ccloud directory, but we have
   basic consumer/producer and then Avro consumer/producer. So assuming we'll need 4 source code links in total for this page?


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


You should see the messages you typed in the previous step.
.. "previous step" is referring to step 3 in the "Produce Records" section?

.. code-block:: bash

       alice   {"count":3}
       alice   {"count":4}
       alice   {"count":5}

#. When you are done, press ``Ctrl-C``.

.. Is the correct source code link?

#. View the :devx-examples:`producer Avro code|clients/cloud/java/src/main/java/io/confluent/examples/clients/cloud/ccloud/ccloud-ccsr-example.sh`.


Schema Evolution with Confluent Cloud Schema Registry
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. View the schema information registered in Confluent Cloud Schema Registry. In
   the output below, substitute values for ``{{ SR_API_KEY }}``,
   ``{{ SR_API_SECRET }}``, and ``{{ SR_ENDPOINT }}``.

   .. code-block:: text

      # View the list of registered subjects
      curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects
      ["test2-value"]

      # View the schema information for subject `test2-value`
      curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects/test2-value/versions/1
      {"subject":"test2-value","version":1,"id":100001,"schema":"{\"type\":\"record\",\"name\":\"myrecord\",\"fields\":[{\"name\":\"count\",\"type\":\"int\"}]}"}

.. this was originally step, but I sectioned it off into a section much like is done in the Java file. In the Java file, there is step #2
   about testing schema compatibility, do we need to add that here?