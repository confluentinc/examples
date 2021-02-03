.. _client-examples-c:

C (librdkafka): Code Example for |ak-tm|
========================================

In this tutorial, you will run a C client application that produces messages to
and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

Client
~~~~~~

-  `librdkafka <https://github.com/edenhill/librdkafka>`__ installed on
   your machine. See the `librdkafka installation
   instructions <https://github.com/edenhill/librdkafka/blob/master/README.md#instructions>`__.

.. include:: includes/certs-truststore.rst

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for C.

   .. code-block:: bash

      cd clients/cloud/c/

#. .. include:: includes/client-example-create-file-librdkafka.rst


Basic Producer and Consumer
----------------------------

.. include:: includes/producer-consumer-description.rst 


Produce Records
~~~~~~~~~~~~~~~

#. Build the example ``producer`` and ``consumer`` applications.

   .. code-block:: bash

      make

#. Verify the build worked. You should see:

   .. code-block:: bash

      cc   consumer.c common.c json.c -o consumer -lrdkafka -lm
      cc   producer.c common.c json.c -o producer -lrdkafka -lm


#. Run the producer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka
     cluster
   - the topic name

   .. code-block:: bash

      ./producer test1 $HOME/.confluent/librdkafka.config

#. Verify the producer sent all the messages. You should see:

   .. code-block:: text

      Creating topic test1
      Topic test1 successfully created
      Producing message #0 to test1: alice={ "count": 1 }
      Producing message #1 to test1: alice={ "count": 2 }
      Producing message #2 to test1: alice={ "count": 3 }
      Producing message #3 to test1: alice={ "count": 4 }
      Producing message #4 to test1: alice={ "count": 5 }
      Producing message #5 to test1: alice={ "count": 6 }
      Producing message #6 to test1: alice={ "count": 7 }
      Producing message #7 to test1: alice={ "count": 8 }
      Producing message #8 to test1: alice={ "count": 9 }
      Producing message #9 to test1: alice={ "count": 10 }
      Waiting for 10 more delivery results
      Message delivered to test1 [0] at offset 0 in 22.75ms: { "count": 1 }
      Message delivered to test1 [0] at offset 1 in 22.77ms: { "count": 2 }
      Message delivered to test1 [0] at offset 2 in 22.77ms: { "count": 3 }
      Message delivered to test1 [0] at offset 3 in 22.78ms: { "count": 4 }
      Message delivered to test1 [0] at offset 4 in 22.78ms: { "count": 5 }
      Message delivered to test1 [0] at offset 5 in 22.78ms: { "count": 6 }
      Message delivered to test1 [0] at offset 6 in 22.78ms: { "count": 7 }
      Message delivered to test1 [0] at offset 7 in 22.79ms: { "count": 8 }
      Message delivered to test1 [0] at offset 8 in 22.80ms: { "count": 9 }
      Message delivered to test1 [0] at offset 9 in 22.81ms: { "count": 10 }
      10/10 messages delivered

#. View the :devx-examples:`producer code|clients/cloud/c/producer.c`.

Consume Records
~~~~~~~~~~~~~~~

#. Run the consumer, passing in arguments for:

   - the topic name you used earlier
   - the local file with configuration parameters to connect to your Kafka
     cluster.

   .. code-block:: bash

      ./consumer test1 $HOME/.confluent/librdkafka.config

#. Verify the consumer received all the messages. You should see:

   .. code-block:: text

      Subscribing to test1, waiting for assignment and messages...
      Press Ctrl-C to exit.
      Received message on test1 [0] at offset 0: { "count": 1 }
      User alice sum 1
      Received message on test1 [0] at offset 1: { "count": 2 }
      User alice sum 3
      Received message on test1 [0] at offset 2: { "count": 3 }
      User alice sum 6
      Received message on test1 [0] at offset 3: { "count": 4 }
      User alice sum 10
      Received message on test1 [0] at offset 4: { "count": 5 }
      User alice sum 15
      Received message on test1 [0] at offset 5: { "count": 6 }
      User alice sum 21
      Received message on test1 [0] at offset 6: { "count": 7 }
      User alice sum 28
      Received message on test1 [0] at offset 7: { "count": 8 }
      User alice sum 36
      Received message on test1 [0] at offset 8: { "count": 9 }
      User alice sum 45
      Received message on test1 [0] at offset 9: { "count": 10 }
      User alice sum 55

#. Press ``Ctrl-C`` to exit.

#. View the :devx-examples:`consumer code|clients/cloud/c/consumer.c`.
