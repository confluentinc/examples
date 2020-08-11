.. _client-examples-python:

Python
======

In this tutorial, you will run a Python client application that produces
messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst

Prerequisites
-------------

Client
~~~~~~

-  A functioning Python environment with the `Confluent Python Client
   for Apache Kafka <https://github.com/confluentinc/confluent-kafka-python>`__
   installed.

-  You can use `Virtualenv <https://virtualenv.pypa.io/en/latest/>`__ and
   run the following commands to create a virtual environment with the client
   installed.

   .. code-block:: bash

      virtualenv ccloud-venv
      source ./ccloud-venv/bin/activate
      pip install -r requirements.txt

- Check your ``confluent-kafka`` library version. The :devx-examples:`requirements.txt|clients/cloud/python/requirements.txt`
  file specifies a version of the ``confluent-kafka`` library >= 1.4.2 which is
  required for the latest Serialization API demonstrated here. If you install the
  library manually or globally, the same version requirements apply.


Configure SSL trust store
^^^^^^^^^^^^^^^^^^^^^^^^^

Depending on your operating system or Linux distro you may need to take extra
steps to set up the SSL CA root certificates. If your system doesn't have the
SSL CA root certificates properly set up, you may receive an error message
similar to the following:

.. code-block:: bash

   %3|1554125834.196|FAIL|rdkafka#producer-2| [thrd:sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/boot]: sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/bootstrap: Failed to verify broker certificate: unable to get issuer certificate (after 626ms in state CONNECT)
   %3|1554125834.197|ERROR|rdkafka#producer-2| [thrd:sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/boot]: sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/bootstrap: Failed to verify broker certificate: unable to get issuer certificate (after 626ms in state CONNECT)
   %3|1554125834.197|ERROR|rdkafka#producer-2| [thrd:sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/boot]: 1/1 brokers are down

macOS
"""""

On newer versions of macOS (for example, 10.15), you may need to add an
additional dependency:

.. code-block:: bash

   pip install certifi

Add the ``ssl.ca.location`` property to the config dict object in
``producer.py`` and ``consumer.py``, and its value should correspond to
the location of the appropriate CA certificates file on your host:

.. code-block:: text

   ssl.ca.location: '/Library/Python/3.7/site-packages/certifi/cacert.pem'

CentOS
""""""

.. code-block:: bash

   sudo yum reinstall ca-certificates

Add the ``ssl.ca.location`` property to the config dict object in
``producer.py`` and ``consumer.py``, and its value should correspond to
the location of the appropriate CA certificates file on your host:


.. code-block:: text

   ssl.ca.location: '/etc/ssl/certs/ca-bundle.crt'

For more information, see the `librdkafka
<https://github.com/edenhill/librdkafka/wiki/Using-SSL-with-librdkafka>`__
documentation on which this Python producer is built.

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for Python.

   .. code-block:: bash

      cd clients/cloud/python/

#. .. include:: includes/client-example-create-file.rst


Basic Producer and Consumer
---------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Run the producer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - topic name

   .. code-block:: bash

      ./producer.py -f $HOME/.confluent/librdkafka.config -t test1

#. Verify that the producer sent all the messages. You should see:

   .. code-block:: bash

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

Consume Records
~~~~~~~~~~~~~~~

#. Run the consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster.
   - the same topic name you used in step 1.

   .. code-block:: bash

      ./consumer.py -f $HOME/.confluent/librdkafka.config -t test1

#. Verify the consumer received all the messages. You should see:

   .. code-block:: bash

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


Avro And Confluent Cloud Schema Registry
----------------------------------------

This example is similar to the previous example, except the key and value are
formatted as Avro and integrates with the |ccloud| |sr|.
Before using |ccloud| |sr|, check its :ref:`availability and limits <cloud-limits>`.

These examples use the latest Serializer API provided by the ``confluent-kafka``
library. The Serializer API replaces the legacy AvroProducer and AvroConsumer
classes to provide a more flexible API including additional support for JSON,
Protobuf, and Avro data formats. See the latest `confluent-kafka documentation
<https://docs.confluent.io/current/clients/confluent-kafka-python/>`__ for
further details.

#. .. include:: includes/client-example-vpc.rst

#. .. include:: includes/client-example-schema-registry-1.rst

#. .. include:: includes/client-example-schema-registry-2.rst

#. .. include:: includes/schema-registry-librdkafka.rst

Produce Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Run the Avro producer, passing in arguments for:

   - the local file with configuration parameters to connect to your Kafka cluster
   - the topic name

   .. code-block:: bash

      ./producer_ccsr.py -f  $HOME/.confluent/librdkafka.config -t test2

#. Verify that the producer sent all the messages. You should see:

   .. code-block:: bash

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

Consume Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Run the Avro consumer, passing in arguments for:

   - the local file with configuration parameters to connect to your
     Kafka cluster
   - the same topic name you used in step 5

   .. code-block:: bash

       ./consumer_ccsr.py -f $HOME/.confluent/librdkafka.config -t test2

#. Verify the consumer received all the messages. You should see:

   .. code-block:: bash

       ./consumer_ccsr.py -f $HOME/.confluent/librdkafka.config -t test2
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


|ccloud| |sr|
~~~~~~~~~~~~~

#. View the schema information registered in |ccloud| Schema
   Registry. In the output below, substitute values for ``{{ SR_API_KEY }}``,
   ``{{ SR_API_SECRET }}``, and ``{{ SR_ENDPOINT }}``.

   .. code-block:: text

      # View the list of registered subjects
      curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects
      ["test2-value"]

      # View the schema information for subject `test2-value`
      curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects/test2-value/versions/1
      {"subject":"test2-value","version":1,"id":100001,"schema":"{\"name\":\"io.confluent.examples.clients.cloud.DataRecordAvro\",\"type\":\"record\",\"fields\":[{\"name\":\"count\",\"type\":\"long\"}]}"}


Run the All the Code in Docker
------------------------------

You can also run all the previous code within Docker.

#. Ensure you have created a local file with configuration parameters to
   connect to your Kafka cluster at ``$HOME/.confluent/librdkafka.config``.

#. Build the Docker image using the following command:

   .. code-block:: bash

      docker build -t cloud-demo-python .

#. Run the Docker image using the following command:

   .. code-block:: bash

      docker run -v $HOME/.confluent/librdkafka.config:/root/.confluent/librdkafka.config -it --rm cloud-demo-python bash

#. Run the Python applications from within the container shell. See earlier
   sections for more details.

   .. code-block:: bash

      root@6970a2a9e65b:/# ./producer.py -f $HOME/.confluent/librdkafka.config -t test1
      root@6970a2a9e65b:/# ./consumer.py -f $HOME/.confluent/librdkafka.config -t test1
      root@6970a2a9e65b:/# ./producer_ccsr.py -f $HOME/.confluent/librdkafka.config -t test2
      root@6970a2a9e65b:/# ./consumer_ccsr.py -f $HOME/.confluent/librdkafka.config -t test2
