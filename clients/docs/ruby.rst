.. _client-examples-ruby:

Ruby: Code Example for |ak-tm|
==============================

In this tutorial, you will run a Ruby client application using the `Zendesk Ruby
Client for Apache Kafka <https://github.com/zendesk/ruby-kafka>`__ that produces
messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst


Prerequisites
-------------

Client
~~~~~~

-  `Bundler <https://bundler.io/>`__ installed on your machine. Install
   using ``gem install bundler``.

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for Ruby.

   .. code-block:: bash

      cd clients/cloud/ruby/

#. .. include:: includes/client-example-create-file-librdkafka.rst


Basic Producer and Consumer
---------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Install gems:

   .. code-block:: bash

       bundle install

#. Run the producer, passing in arguments for:

   - the local file with configuration parameters to connect to your |ak| cluster
   - the topic name

   .. code-block:: bash

      ruby producer.rb -f $HOME/.confluent/librdkafka.config --topic test1

#. Verify the producer sent all the messages. You should see:

   .. code-block:: text

      Creating topic test1
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
      10 messages were successfully produced to topic test1!

#. View the :devx-examples:`producer code|clients/cloud/ruby/producer.rb`.


Consume Records
~~~~~~~~~~~~~~~

#. Run the consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your |ak| cluster
   - the topic name you used earlier

   .. code-block:: bash

      ruby consumer.rb -f $HOME/.confluent/librdkafka.config --topic test1

#. Verify the consumer received all the messages:

   .. code-block:: text

      Consuming messages from test1
      Consumed record with key alice and value {"count":0}, and updated total count 0
      Consumed record with key alice and value {"count":1}, and updated total count 1
      Consumed record with key alice and value {"count":2}, and updated total count 3
      Consumed record with key alice and value {"count":3}, and updated total count 6
      Consumed record with key alice and value {"count":4}, and updated total count 10
      Consumed record with key alice and value {"count":5}, and updated total count 15
      Consumed record with key alice and value {"count":6}, and updated total count 21
      Consumed record with key alice and value {"count":7}, and updated total count 28
      Consumed record with key alice and value {"count":8}, and updated total count 36
      Consumed record with key alice and value {"count":9}, and updated total count 45
      ...

#. View the :devx-examples:`consumer code|clients/cloud/ruby/consumer.rb`.
