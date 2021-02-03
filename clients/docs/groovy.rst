.. _client-examples-groovy:

Groovy: Code Example for |ak-tm|
================================

In this tutorial, you will run a Groovy client application that produces
messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

Client
~~~~~~

-  Java 1.8 or higher to run the demo application.


Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for Groovy.

   .. code-block:: bash

      cd clients/cloud/groovy/

#. .. include:: includes/client-example-create-file-java.rst


Basic Producer and Consumer
---------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Build the client examples:

   .. code-block:: text

      ./gradlew clean build

#. Run the producer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the topic name

   .. code-block:: text

       ./gradlew runApp -PmainClass="io.confluent.examples.clients.cloud.ProducerExample" \
          -PconfigPath="$HOME/.confluent/java.config" \
          -Ptopic="test1"

#. Verify the producer sent all the messages. You should see:

   .. code-block:: text

        ...
        Producing record: alice        {"count":0}
        Producing record: alice        {"count":1}
        Producing record: alice        {"count":2}
        Producing record: alice        {"count":3}
        Producing record: alice        {"count":4}
        Producing record: alice        {"count":5}
        Producing record: alice        {"count":6}
        Producing record: alice        {"count":7}
        Producing record: alice        {"count":8}
        Producing record: alice        {"count":9}
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

#. View the :devx-examples:`producer code|clients/cloud/groovy/src/main/groovy/io/confluent/examples/clients/cloud/ProducerExample.groovy`.


Consume Records
~~~~~~~~~~~~~~~

#. Run the consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the same topic name you used earlier.

   .. code-block:: bash

       ./gradlew runApp -PmainClass="io.confluent.examples.clients.cloud.ConsumerExample"\
            -PconfigPath="$HOME/.confluent/java.config"\
            -Ptopic="test1"

#. Verify the consumer received all the messages. You should see:

   .. code-block:: text

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

#. When you are done, press ``CTRL-C``.

#. View the :devx-examples:`consumer code|clients/cloud/groovy/src/main/groovy/io/confluent/examples/clients/cloud/ConsumerExample.groovy`.


Kafka Streams
~~~~~~~~~~~~~

#. Run the |kstreams| application, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the same topic name you used earlier

   .. code-block:: bash

         ./gradlew runApp -PmainClass="io.confluent.examples.clients.cloud.StreamsExample" \
              -PconfigPath="$HOME/.confluent/java.config" \
              -Ptopic="test1"

#. Verify the consumer received all the messages. You should see:

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

#. When you are done, press ``CTRL-C``.

#. View the :devx-examples:`Kafka Streams code|clients/cloud/groovy/src/main/groovy/io/confluent/examples/clients/cloud/StreamsExample.groovy`.
