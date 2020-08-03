Overview
========

Produce messages to and consume messages from a Kafka cluster using `Confluent
Python Client for Apache Kafka
<https://github.com/confluentinc/confluent-kafka-python>`__.

Prerequisites
=============

-  A functioning python environment with the `Confluent Python Client
   for Apache Kafka <https://github.com/confluentinc/confluent-kafka-python>`__
   installed.

   -  You can use `Virtualenv <https://virtualenv.pypa.io/en/latest/>`__ with
      the following steps to create a virtual environment with the client
      installed.

      -  ``virtualenv ccloud-venv``
      -  ``source ./ccloud-venv/bin/activate``
      -  ``pip install -r requirements.txt``

.. note::

   The `requirements.txt <requirements.txt>`__ file specifies a version of the
   ``confluent-kafka`` library >= 1.4.2 which is required for the latest
   Serialization API demonstrated here. If you install the library manually or
   globally, the same version requirements apply.

-  Create a local file (for example, at ``$HOME/.confluent/librdkafka.config``)
   with configuration parameters to connect to your Kafka cluster, which can be
   on your local host, `Confluent Cloud
   <https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__,
   or any other cluster. Follow `these detailed instructions
   <https://github.com/confluentinc/configuration-templates/tree/master/README.md>`__
   to create the file.

-  If you are running on Confluent Cloud, you must have access to a
   `Confluent Cloud
   <https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__
   cluster

   -  The first 20 users to sign up for `Confluent
      Cloud
      <https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__
      and use the promo code ``C50INTEG`` will receive an additional $50 free
      usage (`details
      <https://www.confluent.io/confluent-cloud-promo-disclaimer/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__).


Configure SSL trust store
-------------------------

Depending on your operating system or Linux distro you may need to take extra
steps to set up the SSL CA root certificates. If your systems does not have the
SSL CA root certificates properly set up, here is an example of an error message
you may see.

.. code-block:: bash

   $ ./producer.py -f $HOME/.confluent/librdkafka.config -t test1
   %3|1554125834.196|FAIL|rdkafka#producer-2| [thrd:sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/boot]: sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/bootstrap: Failed to verify broker certificate: unable to get issuer certificate (after 626ms in state CONNECT)
   %3|1554125834.197|ERROR|rdkafka#producer-2| [thrd:sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/boot]: sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/bootstrap: Failed to verify broker certificate: unable to get issuer certificate (after 626ms in state CONNECT)
   %3|1554125834.197|ERROR|rdkafka#producer-2| [thrd:sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/boot]: 1/1 brokers are down

macOS
~~~~~

On newer versions of macOS (for example, 10.15), it may be required to add an
additional dependency:

.. code-block:: bash

   $ pip install certifi

Add the ``ssl.ca.location`` property to the config dict object in
``producer.py`` and ``consumer.py``, and its value should correspond to
the location of the appropriate CA certificates file on your host:

.. code-block::text

   ssl.ca.location: '/Library/Python/3.7/site-packages/certifi/cacert.pem'

CentOS
~~~~~~

.. code-block:: bash

   $ sudo yum reinstall ca-certificates

Add the ``ssl.ca.location`` property to the config dict object in
``producer.py`` and ``consumer.py``, and its value should correspond to
the location of the appropriate CA certificates file on your host:


.. code-block:: bash

   ssl.ca.location: '/etc/ssl/certs/ca-bundle.crt'

For more information see the librdkafka docs on which this python producer is
built: https://github.com/edenhill/librdkafka/wiki/Using-SSL-with-librdkafka

Example 1: Basic Produce & Consume
==================================

In this example, the producer writes Kafka data to a topic in your Kafka
cluster. Each record has a key representing a username (e.g. ``alice``)
and a value of a count, formatted as json (e.g. ``{"count": 0}``). The
consumer reads the same topic and keeps a rolling sum of the counts as
it processes each record.

#. Run the producer, passing in arguments for (a) the local file with
   configuration parameters to connect to your Kafka cluster and (b) the
   topic name:

   .. code-block:: bash

       $ ./producer.py -f $HOME/.confluent/librdkafka.config -t test1
       Producing record: alice      {"count": 0}
       Producing record: alice      {"count": 1}
       Producing record: alice      {"count": 2}
       Producing record: alice      {"count": 3}
       Producing record: alice      {"count": 4}
       Producing record: alice      {"count": 5}
       Producing record: alice      {"count": 6}
       Producing record: alice      {"count": 7}
       Producing record: alice      {"count": 8}
       Producing record: alice      {"count": 9}
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
       10 messages were produced to topic test1!

#. Run the consumer, passing in arguments for (a) the local file with
   configuration parameters to connect to your Kafka cluster and (b) the same
   topic name as used above. Verify that the consumer received all the messages:

   .. code-block:: bash

      $ ./consumer.py -f $HOME/.confluent/librdkafka.config -t test1
      ...
      Waiting for message or event/error in poll()
      Consumed record with key alice and value {"count": 0}, and updated total count to 0
      Consumed record with key alice and value {"count": 1}, and updated total count to 1
      Consumed record with key alice and value {"count": 2}, and updated total count to 3
      Consumed record with key alice and value {"count": 3}, and updated total count to 6
      Consumed record with key alice and value {"count": 4}, and updated total count to 10
      Consumed record with key alice and value {"count": 5}, and updated total count to 15
      Consumed record with key alice and value {"count": 6}, and updated total count to 21
      Consumed record with key alice and value {"count": 7}, and updated total count to 28
      Consumed record with key alice and value {"count": 8}, and updated total count to 36
      Consumed record with key alice and value {"count": 9}, and updated total count to 45
      Waiting for message or event/error in poll()
      ...


Example 2: Avro And Confluent Cloud Schema Registry
===================================================

This example is similar to the previous example, except the key and value are
formatted as Avro and integrates with the Confluent Cloud Schema Registry.
Before using Confluent Cloud Schema Registry, check its `availability and limits
<https://docs.confluent.io/current/cloud/limits.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__.

.. note::

   Your VPC must be able to connect to the Confluent Cloud Schema Registry
   public internet endpoint.

These examples use the latest Serializer API provided by the ``confluent-kafka``
library. The Serializer API replaces the legacy AvroProducer and AvroConsumer
classes to provide a more flexible API including additional support for JSON,
Protobuf, and Avro data formats. See the latest `confluent-kafka documentation
<https://docs.confluent.io/current/clients/confluent-kafka-python/>`__ for
further details.

#. As described in the `Confluent Cloud
   quickstart <https://docs.confluent.io/current/quickstart/cloud-quickstart/schema-registry.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__,
   in the Confluent Cloud GUI, enable Confluent Cloud Schema Registry
   and create an API key and secret to connect to it.

#. Verify your Confluent Cloud Schema Registry credentials work from your host.
   In the output below, substitute your values for ``{{ SR_API_KEY}}``, ``{{
   SR_API_SECRET }}``, and ``{{ SR_ENDPOINT }}``.

   .. code-block:: shell

      # View the list of registered subjects
      $ curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects

      # Same as above, as a single bash command to parse the values out of  $HOME/.confluent/librdkafka.config
      $ curl -u $(grep "^schema.registry.basic.auth.user.info"  $HOME/.confluent/librdkafka.config | cut -d'=' -f2) $(grep "^schema.registry.url"  $HOME/.confluent/librdkafka.config | cut -d'=' -f2)/subjects

#. Add the following parameters to your local Confluent Cloud
   configuration file. In the output below, substitute values for
   ``{{ SR_API_KEY }}``, ``{{ SR_API_SECRET }}``, and
   ``{{ SR_ENDPOINT }}``.

   .. code-block:: shell

      $ cat $HOME/.confluent/librdkafka.config
      ...
      basic.auth.credentials.source=USER_INFO
      schema.registry.basic.auth.user.info={{ SR_API_KEY }}:{{ SR_API_SECRET }}
      schema.registry.url=https://{{ SR_ENDPOINT }}
      ...

#. Create the topic in Confluent Cloud.

   .. code-block:: bash

       $ kafka-topics --bootstrap-server `grep "^\s*bootstrap.server"  $HOME/.confluent/librdkafka.config | tail -1` --command-config  $HOME/.confluent/librdkafka.config --topic test2 --create --replication-factor 3 --partitions 6

#. Run the Avro producer, passing in arguments for (a) the local file
   with configuration parameters to connect to your Kafka cluster and
   (b) the topic name:

.. code-block:: bash

   $ ./producer_ccsr.py -f  $HOME/.confluent/librdkafka.config -t test2
   Producing Avro record: alice    0
   Producing Avro record: alice    1
   Producing Avro record: alice    2
   Producing Avro record: alice    3
   Producing Avro record: alice    4
   Producing Avro record: alice    5
   Producing Avro record: alice    6
   Producing Avro record: alice    7
   Producing Avro record: alice    8
   Producing Avro record: alice    9
   Produced record to topic test2 partition [0] @ offset 0
   Produced record to topic test2 partition [0] @ offset 1
   Produced record to topic test2 partition [0] @ offset 2
   Produced record to topic test2 partition [0] @ offset 3
   Produced record to topic test2 partition [0] @ offset 4
   Produced record to topic test2 partition [0] @ offset 5
   Produced record to topic test2 partition [0] @ offset 6
   Produced record to topic test2 partition [0] @ offset 7
   Produced record to topic test2 partition [0] @ offset 8
   Produced record to topic test2 partition [0] @ offset 9
   10 messages were produced to topic test2!

#. Run the Avro consumer, passing in arguments for the following items:

   a. The local file with configuration parameters to connect to your
      Kafka cluster
   b. The same topic name as used above. Verify that the consumer received all
      the messages:

   .. code-block:: bash

       $ ./consumer_ccsr.py -f $HOME/.confluent/librdkafka.config -t test2
       ...
       Waiting for message or event/error in poll()
       Consumed record with key alice and value 0,                       and updated total count to 0
       Consumed record with key alice and value 1,                       and updated total count to 1
       Consumed record with key alice and value 2,                       and updated total count to 3
       Consumed record with key alice and value 3,                       and updated total count to 6
       Consumed record with key alice and value 4,                       and updated total count to 10
       Consumed record with key alice and value 5,                       and updated total count to 15
       Consumed record with key alice and value 6,                       and updated total count to 21
       Consumed record with key alice and value 7,                       and updated total count to 28
       Consumed record with key alice and value 8,                       and updated total count to 36
       Consumed record with key alice and value 9,                       and updated total count to 45
       ...

#. View the schema information registered in Confluent Cloud Schema
   Registry. In the output below, substitute values for ``{{ SR_API_KEY }}``,
   ``{{ SR_API_SECRET }}``, and ``{{ SR_ENDPOINT }}``.

   ::

      # View the list of registered subjects
      $ curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects
      ["test2-value"]

      # View the schema information for subject `test2-value`
      $ curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects/test2-value/versions/1
      {"subject":"test2-value","version":1,"id":100001,"schema":"{\"name\":\"io.confluent.examples.clients.cloud.DataRecordAvro\",\"type\":\"record\",\"fields\":[{\"name\":\"count\",\"type\":\"long\"}]}"}

Example 3: Run All the Above in Docker
======================================

You also may run all the above code from within Docker.

#. Ensure you have created a local file with configuration parameters to
   connect to your Kafka cluster at ``$HOME/.confluent/librdkafka.config``.

#. Build the Docker image using the following command:

   .. code-block:: bash

      $ docker build -t cloud-demo-python .

#. Run the Docker image using the following command:

   .. code-block:: bash

      $ docker run -v $HOME/.confluent/librdkafka.config:/root/.confluent/librdkafka.config -it --rm cloud-demo-python bash

#. Run the python applications from within the container shell using the following command (see earlier
   sections for more details):

   .. code-block:: bash

      root@6970a2a9e65b:/# ./producer.py -f $HOME/.confluent/librdkafka.config -t test1
      root@6970a2a9e65b:/# ./consumer.py -f $HOME/.confluent/librdkafka.config -t test1
      root@6970a2a9e65b:/# ./producer_ccsr.py -f $HOME/.confluent/librdkafka.config -t test2
      root@6970a2a9e65b:/# ./consumer_ccsr.py -f $HOME/.confluent/librdkafka.config -t test2
