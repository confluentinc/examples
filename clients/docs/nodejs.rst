.. _client-examples-nodejs:

Node.js: Code Example for |ak-tm|
=================================

In this tutorial, you will run a Node.js client application that produces
messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

Client
~~~~~~

-  `Node.js <https://nodejs.org/>`__ version 8.6 or higher installed on
   your local machine.

-  Users of macOS 10.13 (High Sierra) and later should read `node-rdkafka’s
   additional configuration instructions related to OpenSSL
   <https://github.com/Blizzard/node-rdkafka/blob/56c31c4e81f2a042666160338ad65dc4f8f2d87e/README.md#mac-os-high-sierra--mojave>`__
   before running ``npm install``.

-  `OpenSSL <https://www.openssl.org>`__ version 1.0.2.

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for Node.js.

   .. code-block:: bash

      cd clients/cloud/nodejs/

#. .. include:: includes/client-example-create-file-librdkafka.rst


Basic Producer and Consumer
---------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Install npm dependencies.

   .. code-block:: bash

      npm install

#. Run the producer, passing in arguments for:

   - the local file with configuration parameters to connect to your |ak|
     cluster
   - the topic name

   .. code-block:: bash

       node producer.js -f $HOME/.confluent/librdkafka.config -t test1

#. Verify the producer sent all the messages. You should see:

   .. code-block:: text

      Created topic test1
      Producing record alice	{"count":0}
      Producing record alice	{"count":1}
      Producing record alice	{"count":2}
      Producing record alice	{"count":3}
      Producing record alice	{"count":4}
      Producing record alice	{"count":5}
      Producing record alice	{"count":6}
      Producing record alice	{"count":7}
      Producing record alice	{"count":8}
      Producing record alice	{"count":9}
      Successfully produced record to topic "test1" partition 0 {"count":0}
      Successfully produced record to topic "test1" partition 0 {"count":1}
      Successfully produced record to topic "test1" partition 0 {"count":2}
      Successfully produced record to topic "test1" partition 0 {"count":3}
      Successfully produced record to topic "test1" partition 0 {"count":4}
      Successfully produced record to topic "test1" partition 0 {"count":5}
      Successfully produced record to topic "test1" partition 0 {"count":6}
      Successfully produced record to topic "test1" partition 0 {"count":7}
      Successfully produced record to topic "test1" partition 0 {"count":8}
      Successfully produced record to topic "test1" partition 0 {"count":9}

#. View the :devx-examples:`producer code|clients/cloud/nodejs/producer.js`.


Consume Records
~~~~~~~~~~~~~~~

#. Run the consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your |ak| cluster
   - the topic name you used earlier

   .. code-block:: bash

       node consumer.js -f $HOME/.confluent/librdkafka.config -t test1

#. Verify the consumer received all the messages:

   .. code-block:: text

      Consuming messages from test1
      Consumed record with key alice and value {"count":0} of partition 0 @ offset 0. Updated total count to 1
      Consumed record with key alice and value {"count":1} of partition 0 @ offset 1. Updated total count to 2
      Consumed record with key alice and value {"count":2} of partition 0 @ offset 2. Updated total count to 3
      Consumed record with key alice and value {"count":3} of partition 0 @ offset 3. Updated total count to 4
      Consumed record with key alice and value {"count":4} of partition 0 @ offset 4. Updated total count to 5
      Consumed record with key alice and value {"count":5} of partition 0 @ offset 5. Updated total count to 6
      Consumed record with key alice and value {"count":6} of partition 0 @ offset 6. Updated total count to 7
      Consumed record with key alice and value {"count":7} of partition 0 @ offset 7. Updated total count to 8
      Consumed record with key alice and value {"count":8} of partition 0 @ offset 8. Updated total count to 9
      Consumed record with key alice and value {"count":9} of partition 0 @ offset 9. Updated total count to 10

#. View the :devx-examples:`consumer code|clients/cloud/nodejs/consumer.js`.
