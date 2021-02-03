.. _client-examples-rust:

Rust: Code Example for |ak-tm|
==============================

In this tutorial, you will run a Rust client application that produces messages
to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

Client
~~~~~~

-  `Rust client for Apache
   Kafka <https://github.com/fede1024/rust-rdkafka#installation>`__ installed on
   your machine

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for Rust.

   .. code-block:: bash

      cd clients/cloud/rust/

#. .. include:: includes/client-example-create-file-librdkafka.rst


Basic Consumer and Producer
---------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Build the producer and consumer binaries:

   .. code-block:: bash

      cargo build

   You should see:

   .. code-block:: text

       Compiling rust_kafka_client_example v0.1.0 (/path/to/repo/examples/clients/cloud/rust)
       Finished dev [unoptimized + debuginfo] target(s) in 2.85s

#. Run the producer, passing in arguments for:

   -  the local file with configuration parameters to connect to your |ak| cluster
   -  the topic name

   .. code-block:: bash

      ./target/debug/producer --config $HOME/.confluent/librdkafka.config --topic test1


#. Verify the producer sent all the messages. You should see:

   .. code-block:: text

      Preparing to produce record: alice 0
      Preparing to produce record: alice 1
      Preparing to produce record: alice 2
      Preparing to produce record: alice 3
      Preparing to produce record: alice 4
      Preparing to produce record: alice 5
      Preparing to produce record: alice 6
      Preparing to produce record: alice 7
      Preparing to produce record: alice 8
      Successfully produced record to topic test1 partition [5] @ offset 117
      Successfully produced record to topic test1 partition [5] @ offset 118
      Successfully produced record to topic test1 partition [5] @ offset 119
      Successfully produced record to topic test1 partition [5] @ offset 120
      Successfully produced record to topic test1 partition [5] @ offset 121
      Successfully produced record to topic test1 partition [5] @ offset 122
      Successfully produced record to topic test1 partition [5] @ offset 123
      Successfully produced record to topic test1 partition [5] @ offset 124
      Successfully produced record to topic test1 partition [5] @ offset 125

#. View the :devx-examples:`producer code|clients/cloud/rust/src/producer.rs`.


Consume Records
~~~~~~~~~~~~~~~


#. Run the consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your |ak| cluster
   - the topic name you used earlier

   .. code-block:: bash

      ./target/debug/consumer --config $HOME/.confluent/librdkafka.config --topic test1

#. Verify the consumer received all the messages. You should see:

   .. code-block:: text

      Consumed record from topic test1 partition [5] @ offset 117 with key alice and value 0
      Consumed record from topic test1 partition [5] @ offset 118 with key alice and value 1
      Consumed record from topic test1 partition [5] @ offset 119 with key alice and value 2
      Consumed record from topic test1 partition [5] @ offset 120 with key alice and value 3
      Consumed record from topic test1 partition [5] @ offset 121 with key alice and value 4
      Consumed record from topic test1 partition [5] @ offset 122 with key alice and value 5
      Consumed record from topic test1 partition [5] @ offset 123 with key alice and value 6
      Consumed record from topic test1 partition [5] @ offset 124 with key alice and value 7
      Consumed record from topic test1 partition [5] @ offset 125 with key alice and value 8

#. View the :devx-examples:`consumer code|clients/cloud/rust/src/consumer.rs`.
