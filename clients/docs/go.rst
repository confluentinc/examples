.. _client-examples-go:

Go
===

In this tutorial, you will run a Golang client application that produces
messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst

Prerequisites
-------------

Client
~~~~~~

-  A functioning Go environment with the `Confluent Golang Client
   for Apache Kafka <https://github.com/confluentinc/confluent-kafka-go>`__
   installed.


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

#. Change directory to the example for Go.

   .. code-block:: bash

      cd clients/cloud/go/

#. .. include:: includes/client-example-create-file.rst


Basic Producer and Consumer
---------------------------

In this example, the producer writes Kafka data to a topic in your Kafka
cluster. Each record has a key representing a username (for example, ``alice``)
and a value of a count, in JSON format (for example, ``{"Count": 0}``). The
consumer reads the same topic and keeps a rolling sum of the counts as it
processes each record.


Produce Records
~~~~~~~~~~~~~~~

#. Run the producer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - topic name

   .. code-block:: bash

      go build producer.go

   You should see:

   .. code-block:: bash

      Preparing to produce record: alice   {"Count": 0}
      Preparing to produce record: alice   {"Count": 1}
      Preparing to produce record: alice   {"Count": 2}
      Preparing to produce record: alice   {"Count": 3}
      Preparing to produce record: alice   {"Count": 4}
      Preparing to produce record: alice   {"Count": 5}
      Preparing to produce record: alice   {"Count": 6}
      Preparing to produce record: alice   {"Count": 7}
      Preparing to produce record: alice   {"Count": 8}
      Preparing to produce record: alice   {"Count": 9}
      Successfully produced record to topic test1 partition [0] @ offset 0
      Successfully produced record to topic test1 partition [0] @ offset 1
      Successfully produced record to topic test1 partition [0] @ offset 2
      Successfully produced record to topic test1 partition [0] @ offset 3
      Successfully produced record to topic test1 partition [0] @ offset 4
      Successfully produced record to topic test1 partition [0] @ offset 5
      Successfully produced record to topic test1 partition [0] @ offset 6
      Successfully produced record to topic test1 partition [0] @ offset 7
      Successfully produced record to topic test1 partition [0] @ offset 8
      Successfully produced record to topic test1 partition [0] @ offset 9
      10 messages were produced to topic test1!


#. View the :devx-examples:`producer code|clients/cloud/go/producer.go`.


Consume Records
~~~~~~~~~~~~~~~

#. Run the consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka
     cluster
   - the same topic name used in step 1

#. Verify the consumer received all the messages. You should see:

   .. code-block:: bash

      go build consumer.go

   .. code-block:: bash

      ...
      Consumed record with key alice and value {"Count":0}, and updated total count to 0
      Consumed record with key alice and value {"Count":1}, and updated total count to 1
      Consumed record with key alice and value {"Count":2}, and updated total count to 3
      Consumed record with key alice and value {"Count":3}, and updated total count to 6
      Consumed record with key alice and value {"Count":4}, and updated total count to 10
      Consumed record with key alice and value {"Count":5}, and updated total count to 15
      Consumed record with key alice and value {"Count":6}, and updated total count to 21
      Consumed record with key alice and value {"Count":7}, and updated total count to 28
      Consumed record with key alice and value {"Count":8}, and updated total count to 36
      Consumed record with key alice and value {"Count":9}, and updated total count to 45
      ...


#. View the :devx-examples:`consumer code|clients/cloud/go/consumer.go`.