.. _client-examples-java:

Java: Code Example for |ak-tm|
==============================

In this tutorial, you will run a Java client application that produces
messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

Client
~~~~~~

-  Java 1.8 or higher to run the demo application.

-  Maven to compile the demo application.


Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for Java.

   .. code-block:: bash

      cd clients/cloud/java/

#. .. include:: includes/client-example-create-file-java.rst


Basic Producer and Consumer and Kafka Streams
---------------------------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Compile the Java code.

   .. code-block:: bash

       mvn clean package

#. Run the producer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the topic name

   .. code-block:: bash

      mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" \
      -Dexec.args="$HOME/.confluent/java.config test1"

#. Verify that the producer sent all the messages. You should see:

   .. code-block:: text

      ...
      Producing record: alice {"count":0}
      Producing record: alice {"count":1}
      Producing record: alice {"count":2}
      Producing record: alice {"count":3}
      Producing record: alice {"count":4}
      Producing record: alice {"count":5}
      Producing record: alice {"count":6}
      Producing record: alice {"count":7}
      Producing record: alice {"count":8}
      Producing record: alice {"count":9}
      Produced record to topic test1 partition [0] @ offset 0
      Produced record to topic test1 partition [0] @ offset 1
      Produced record to topic test1 partition [0] @ offset 2
      Produced record to topic test1 partition [0] @ offset 3
      Produced record to topic test1 partition [0] @ offset 4
      Produced record to topic test1 partition [0] @ offset 5
      Produced record to topic test1 partition [0] @ offset 6
      Produced record to topic test1 partition [0] @ offset 7
      Produced record to topic test1 partition [0] @ offset 8
      Produced record to topic test1 partition [0] @ offset 9
      10 messages were produced to topic test1
      ...

#. View the :devx-examples:`producer code|clients/cloud/java/src/main/java/io/confluent/examples/clients/cloud/ProducerExample.java`.


Consume Records
~~~~~~~~~~~~~~~

#. Run the consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the topic name you used earlier

   .. code-block:: bash

      mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ConsumerExample" \
      -Dexec.args="$HOME/.confluent/java.config test1"

#. Verify the consumer received all the messages. You should see:

   .. code-block:: text

      ...
      Polling
      Consumed record with key alice and value {"count":0}, and updated total count to 0
      Consumed record with key alice and value {"count":1}, and updated total count to 1
      Consumed record with key alice and value {"count":2}, and updated total count to 3
      Consumed record with key alice and value {"count":3}, and updated total count to 6
      Consumed record with key alice and value {"count":4}, and updated total count to 10
      Consumed record with key alice and value {"count":5}, and updated total count to 15
      Consumed record with key alice and value {"count":6}, and updated total count to 21
      Consumed record with key alice and value {"count":7}, and updated total count to 28
      Consumed record with key alice and value {"count":8}, and updated total count to 36
      Consumed record with key alice and value {"count":9}, and updated total count to 45
      Polling
      ...

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`consumer code|clients/cloud/java/src/main/java/io/confluent/examples/clients/cloud/ConsumerExample.java`.


Kafka Streams
~~~~~~~~~~~~~

#. Run the |kstreams| application, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka
     cluster
   - the topic name you used earlier

   .. code-block:: bash

      mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.StreamsExample" \
      -Dexec.args="$HOME/.confluent/java.config test1"

#. Verify that the |kstreams| application processed all the messages. You should see:

   .. code-block:: text

      ...
      [Consumed record]: alice, 0
      [Consumed record]: alice, 1
      [Consumed record]: alice, 2
      [Consumed record]: alice, 3
      [Consumed record]: alice, 4
      [Consumed record]: alice, 5
      [Consumed record]: alice, 6
      [Consumed record]: alice, 7
      [Consumed record]: alice, 8
      [Consumed record]: alice, 9
      ...
      [Running count]: alice, 0
      [Running count]: alice, 1
      [Running count]: alice, 3
      [Running count]: alice, 6
      [Running count]: alice, 10
      [Running count]: alice, 15
      [Running count]: alice, 21
      [Running count]: alice, 28
      [Running count]: alice, 36
      [Running count]: alice, 45
      ...

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`Kafka Streams code|clients/cloud/java/src/main/java/io/confluent/examples/clients/cloud/StreamsExample.java`.


Avro and Confluent Cloud Schema Registry
-----------------------------------------

.. include:: includes/schema-registry-scenario-explain.rst

#. .. include:: includes/client-example-schema-registry-1.rst

#. .. include:: includes/client-example-vpc.rst

#. .. include:: includes/schema-registry-java.rst

#. .. include:: includes/client-example-schema-registry-2-java.rst


Produce Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Run the Avro producer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the topic name

   .. code-block:: bash

      mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerAvroExample" \
      -Dexec.args="$HOME/.confluent/java.config test2"

#. View the :devx-examples:`producer Avro code|clients/cloud/java/src/main/java/io/confluent/examples/clients/cloud/ProducerAvroExample.java`.


Consume Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Run the Avro consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the topic name

   .. code-block:: bash

      mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ConsumerAvroExample" \
      -Dexec.args="$HOME/.confluent/java.config test2"

#. View the :devx-examples:`consumer Avro code|clients/cloud/java/src/main/java/io/confluent/examples/clients/cloud/ConsumerAvroExample.java`.


Avro Kafka Streams
~~~~~~~~~~~~~~~~~~

#. Run the Avro |kstreams| application, passing in arguments for:

   -  the local file with configuration parameters to connect to your Kafka
      cluster
   -  the same topic name you used earlier

   .. code-block:: bash

      mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.StreamsAvroExample" \
      -Dexec.args="$HOME/.confluent/java.config test2"

#. View the :devx-examples:`Kafka Streams Avro code|clients/cloud/java/src/main/java/io/confluent/examples/clients/cloud/StreamsAvroExample.java`.


Schema Evolution with Confluent Cloud Schema Registry
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. View the schema subjects registered in |sr-ccloud|. In the following output, substitute values for ``<SR API KEY>``, ``<SR API SECRET>``, and ``<SR ENDPOINT>``.

   .. code-block:: text

      curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects

#. Verify that the subject ``test2-value`` exists.

   .. code-block:: text

      ["test2-value"]

#. View the schema information for subject `test2-value`. In the following output, substitute values for ``<SR API KEY>``, ``<SR API SECRET>``, and ``<SR ENDPOINT>``.

   .. code-block:: text

      curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects/test2-value/versions/1

#. Verify the schema information for subject ``test2-value``.

   .. code-block:: text

      {"subject":"test2-value","version":1,"id":100001,"schema":"{\"name\":\"io.confluent.examples.clients.cloud.DataRecordAvro\",\"type\":\"record\",\"fields\":[{\"name\":\"count\",\"type\":\"long\"}]}"}

#. For schema evolution, you can `test schema
   compatibility
   <https://docs.confluent.io/platform/current/schema-registry/develop/maven-plugin.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud#schema-registry-test-compatibility>`__
   between newer schema versions and older schema versions in |ccloud| |sr|. The
   :devx-examples:`pom.xml|clients/cloud/java/pom.xml` hardcodes the Schema
   Registry subject name to ``test2-value``—change this if you didn't use topic
   name ``test2``. Then test local schema compatibility for
   :devx-examples:`DataRecordAvro2a.avsc|clients/cloud/java/src/main/resources/avro/io/confluent/examples/clients/cloud/DataRecordAvro2a.avsc`,
   which should fail, and
   :devx-examples:`DataRecordAvro2b.avsc|clients/cloud/java/src/main/resources/avro/io/confluent/examples/clients/cloud/DataRecordAvro2b.avsc`,
   which should pass.

   .. code-block:: text

      # DataRecordAvro2a.avsc compatibility test: FAIL
      mvn schema-registry:test-compatibility "-DschemaRegistryUrl=https://{{ SR_ENDPOINT }}" "-DschemaRegistryBasicAuthUserInfo={{ SR_API_KEY }}:{{ SR_API_SECRET }}" "-DschemaLocal=src/main/resources/avro/io/confluent/examples/clients/cloud/DataRecordAvro2a.avsc"

      # DataRecordAvro2b.avsc compatibility test: PASS
      mvn schema-registry:test-compatibility "-DschemaRegistryUrl=https://{{ SR_ENDPOINT }}" "-DschemaRegistryBasicAuthUserInfo={{ SR_API_KEY }}:{{ SR_API_SECRET }}" "-DschemaLocal=src/main/resources/avro/io/confluent/examples/clients/cloud/DataRecordAvro2b.avsc"
