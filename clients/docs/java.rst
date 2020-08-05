.. _client-examples-java:

Java
====

In this tutorial, you will run a Golang client application that produces
messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst

Prerequisites
-------------

Client
~~~~~~

-  Java 1.8 or higher to run the demo application

-  Maven to compile the demo application


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

#. Change directory to the example for Java.

   .. code-block:: bash

      cd clients/cloud/java/

#. .. include:: includes/client-example-create-file.rst


Basic Producer and Consumer
---------------------------

In this example, the producer writes Kafka data to a topic in your Kafka
cluster. Each record has a key representing a username (for example, ``alice``)
and a value of a count, in JSON format (for example, ``{"Count": 0}``). The
consumer reads the same topic and keeps a rolling sum of the counts as it
processes each record.


Producer
~~~~~~~~~

#. Run the producer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - topic name

   .. code-block:: text

      # Compile the Java code
      mvn clean package

      # Run the producer
          # If the topic does not already exist, the code will use the Kafka Admin Client API to create the topic
      mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerExample" \
      -Dexec.args="$HOME/.confluent/java.config test1"

   You should see:

   .. code-block:: bash

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


Consume
~~~~~~~

#. Run the consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the same topic name you used in step 1.

   .. code-block:: text

      # Compile the Java code
      mvn clean package

      # Run the consumer
      mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ConsumerExample" \
      -Dexec.args="$HOME/.confluent/java.config test1"


#. Verify that the consumer received all the messages. You should see:

   .. code-block:: bash

      ...
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

#. When you are done, press ``<ctrl>-c``.

#. Run the Kafka Streams application, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka
     cluster
   - the same topic name you used earlier.

   .. code:-block: text

      # Compile the Java code
      $ mvn clean package

      # Run the Kafka streams application
      $ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.StreamsExample" \
        -Dexec.args="$HOME/.confluent/java.config test1"

   You should see:

   .. code:-block: bash

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

#. When you are done, press ``<ctrl>-c``.


Avro and Confluent Cloud Schema Registry
-----------------------------------------

This example is similar to the previous example, except the value is formatted
as Avro and integrates with the |ccloud| |sr|. Before using |ccloud| |sr|, check
its |ccloud| |sr|.

#. .. include:: includes/client-example-vpc.rst

#. .. include:: includes/client-example-schema-registry-1.rst

#. .. include:: includes/client-example-schema-registry-2.rst

#. .. include:: includes/schema-registry-librdkafka.rst


#. Run the Avro producer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the topic name

   .. code:-block: text

      # Compile the Java code
      mvn clean package

      # Run the Avro producer
        # If the topic does not already exist, the code will use the Kafka Admin Client API to create the topic
      mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ProducerAvroExample" \
      -Dexec.args="$HOME/.confluent/java.config test2"

#. Run the Avro consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the topic name:

   .. code:-block: text

      # Compile the Java code
      mvn clean package

      # Run the Avro consumer
      mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.ConsumerAvroExample" \
      -Dexec.args="$HOME/.confluent/java.config test2"

#. Run the Avro Kafka Streams application, passing in arguments for (a)
   the local file with configuration parameters to connect to your Kafka
   cluster and (b) the same topic name as used above. Verify that the
   application received all the messages:

   ::

      # Compile the Java code
      $ mvn clean package

      # Run the Avro Kafka streams application
      $ mvn exec:java -Dexec.mainClass="io.confluent.examples.clients.cloud.StreamsAvroExample" \
        -Dexec.args="$HOME/.confluent/java.config test2"

Schema Evolution with Confluent Cloud Schema Registry
-----------------------------------------------------

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
      {"subject":"test2-value","version":1,"id":100001,"schema":"{\"name\":\"io.confluent.examples.clients.cloud.DataRecordAvro\",\"type\":\"record\",\"fields\":[{\"name\":\"count\",\"type\":\"long\"}]}"}

8. For schema evolution, you can `test schema
   compatibility <https://docs.confluent.io/current/schema-registry/develop/maven-plugin.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud#schema-registry-test-compatibility>`__
   between newer schema versions and older schema versions in Confluent
   Cloud Schema Registry. The `pom.xml <pom.xml>`__ hardcodes the Schema
   Registry subject name to ``test2-value``—change this if you did not
   use topic name ``test2``. Then test local schema compatibility for
   `src/main/resources/avro/io/confluent/examples/clients/cloud/DataRecordAvro2a.avsc <src/main/resources/avro/io/confluent/examples/clients/cloud/DataRecordAvro2a.avsc>`__,
   which should fail, and
   `src/main/resources/avro/io/confluent/examples/clients/cloud/DataRecordAvro2b.avsc <src/main/resources/avro/io/confluent/examples/clients/cloud/DataRecordAvro2b.avsc>`__,
   which should pass.

   ::

      # DataRecordAvro2a.avsc compatibility test: FAIL
      $ mvn schema-registry:test-compatibility "-DschemaRegistryUrl=https://{{ SR_ENDPOINT }}" "-DschemaRegistryBasicAuthUserInfo={{ SR_API_KEY }}:{{ SR_API_SECRET }}" "-DschemaLocal=src/main/resources/avro/io/confluent/examples/clients/cloud/DataRecordAvro2a.avsc"

      # DataRecordAvro2b.avsc compatibility test: PASS
      $ mvn schema-registry:test-compatibility "-DschemaRegistryUrl=https://{{ SR_ENDPOINT }}" "-DschemaRegistryBasicAuthUserInfo={{ SR_API_KEY }}:{{ SR_API_SECRET }}" "-DschemaLocal=src/main/resources/avro/io/confluent/examples/clients/cloud/DataRecordAvro2b.avsc"
