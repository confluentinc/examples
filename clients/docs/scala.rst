.. _client-examples-scala:

Scala: Code Example for |ak-tm|
===============================

In this tutorial, you will run a Scala client application that produces messages
to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

Client
~~~~~~

-  Scala ``sbt``.

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for Scala.

   .. code-block:: bash

      cd clients/cloud/scala/

#. .. include:: includes/client-example-create-file-java.rst


Basic Producer and Consumer
---------------------------

.. include:: includes/producer-consumer-description.rst

Produce Records
~~~~~~~~~~~~~~~

#. Compile the Scala code:

   .. code-block:: bash

      sbt clean compile

#. Run the producer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the topic name

   .. code-block:: bash

      sbt "runMain io.confluent.examples.clients.scala.Producer $HOME/.confluent/java.config test1"

#. Verify that the producer sent all the messages. You should see:

   .. code-block:: text

         <snipped>
         Produced record at test1-0@120
         Produced record at test1-0@121
         Produced record at test1-0@122
         Produced record at test1-0@123
         Produced record at test1-0@124
         Produced record at test1-0@125
         Produced record at test1-0@126
         Produced record at test1-0@127
         Produced record at test1-0@128
         Produced record at test1-0@129
         Wrote ten records to test1
         [success] Total time: 6 s, completed 10-Dec-2018 16:50:13

#. View the :devx-examples:`producer code|clients/cloud/scala/src/main/scala/io/confluent/examples/clients/scala/Producer.scala`.


Consume Records
~~~~~~~~~~~~~~~

#. Run the consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the topic name you used earlier

   .. code-block:: bash

      sbt "runMain io.confluent.examples.clients.scala.Consumer $HOME/.confluent/java.config test1"

#. Verify the consumer received all the messages. You should see:

   .. code-block:: text

      ...
      Consumed record with key alice and value {"count":1}, and updated total count to 1
      Consumed record with key alice and value {"count":2}, and updated total count to 3
      Consumed record with key alice and value {"count":3}, and updated total count to 6
      Consumed record with key alice and value {"count":4}, and updated total count to 10
      Consumed record with key alice and value {"count":5}, and updated total count to 15
      Consumed record with key alice and value {"count":6}, and updated total count to 21
      Consumed record with key alice and value {"count":7}, and updated total count to 28
      Consumed record with key alice and value {"count":8}, and updated total count to 36
      Consumed record with key alice and value {"count":9}, and updated total count to 45
      Consumed record with key alice and value {"count":10}, and updated total count to 55
      ...

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`consumer code|clients/cloud/scala/src/main/scala/io/confluent/examples/clients/scala/Consumer.scala`.


Kafka Streams
~~~~~~~~~~~~~

#. Run the |kstreams| application, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka
     cluster
   - the topic name you used earlier

   .. code-block:: bash

      sbt "runMain io.confluent.examples.clients.scala.Streams $HOME/.confluent/java.config test1"

#. In the streams app, verify you see the following output:

   .. code-block:: text

      ...
      [Consumed record]: alice, 1
      [Consumed record]: alice, 2
      [Consumed record]: alice, 3
      [Consumed record]: alice, 4
      [Consumed record]: alice, 5
      [Consumed record]: alice, 6
      [Consumed record]: alice, 7
      [Consumed record]: alice, 8
      [Consumed record]: alice, 9
      [Consumed record]: alice, 10
      [Running count]: alice, 1
      [Running count]: alice, 3
      [Running count]: alice, 6
      [Running count]: alice, 10
      [Running count]: alice, 15
      [Running count]: alice, 21
      [Running count]: alice, 28
      [Running count]: alice, 36
      [Running count]: alice, 45
      [Running count]: alice, 55
      ...

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`Kafka Streams code|clients/cloud/scala/src/main/scala/io/confluent/examples/clients/scala/Streams.scala`.

Suggested Resources
-------------------

- Blog post: `Getting Started with Scala and Apache Kafka <https://www.confluent.io/blog/kafka-scala-tutorial-for-beginners/>`__
