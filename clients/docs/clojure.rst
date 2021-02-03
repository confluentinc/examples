.. _client-examples-clojure:

Clojure: Code Example for |ak-tm|
=================================

In this tutorial, you will run a Clojure client application that produces
messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

Client
~~~~~~

-  Java 8 or higher (Clojure 1.10 recommends using Java 8 or Java 11)

-  The `Leiningen <https://leiningen.org/#install>`__ tool to compile
   and run the demos

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for Clojure.

   .. code-block:: bash

      cd clients/cloud/clojure/

#. .. include:: includes/client-example-create-file-java.rst


Basic Producer and Consumer
---------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Run the producer, passing in arguments for:

   - the local file with configuration parameters to connect to your |ak| cluster
   - the topic name

   .. code-block:: bash

      lein producer $HOME/.confluent/java.config test1

   You should see:

   .. code-block:: text

         …
         Producing record: alice     {"count":0}
         Producing record: alice     {"count":1}
         Producing record: alice     {"count":2}
         Producing record: alice     {"count":3}
         Producing record: alice     {"count":4}
         Produced record to topic test1 partition [0] @ offest 0
         Produced record to topic test1 partition [0] @ offest 1
         Produced record to topic test1 partition [0] @ offest 2
         Produced record to topic test1 partition [0] @ offest 3
         Produced record to topic test1 partition [0] @ offest 4
         Producing record: alice     {"count":5}
         Producing record: alice     {"count":6}
         Producing record: alice     {"count":7}
         Producing record: alice     {"count":8}
         Producing record: alice     {"count":9}
         Produced record to topic test1 partition [0] @ offest 5
         Produced record to topic test1 partition [0] @ offest 6
         Produced record to topic test1 partition [0] @ offest 7
         Produced record to topic test1 partition [0] @ offest 8
         Produced record to topic test1 partition [0] @ offest 9
         10 messages were produced to topic test1!


#. View the :devx-examples:`producer code|clients/cloud/clojure/src/io/confluent/examples/clients/clj/producer.clj`

Consume Records
~~~~~~~~~~~~~~~

#. Run the consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your |ak| cluster
   - the topic name you used earlier

   .. code-block:: bash

      lein consumer $HOME/.confluent/java.config test1

#. Verify the consumer received all the messages. You should see:

   .. code-block:: text

      …
      Waiting for message in KafkaConsumer.poll
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
      Waiting for message in KafkaConsumer.poll
      …

#. View the :devx-examples:`consumer code|clients/cloud/clojure/src/io/confluent/examples/clients/clj/consumer.clj`
