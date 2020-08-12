.. _client-examples-java-springboot:

Java Spring Boot
================

In this tutorial, you will run a Java Spring Boot client application that
produces messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst

Prerequisites
--------------

Client
~~~~~~

-  Java 1.8.


Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for Java Spring Boot.

   .. code-block:: bash

      cd clients/cloud/java-springboot/

#. .. include:: includes/client-example-create-file-java.rst

.. admonition:: Confluent Cloud config example

   .. code-block:: text

      cat $HOME/.ccloud/java.config bootstrap.servers=<BROKER ENDPOINT>
      ssl.endpoint.identification.algorithm=https security.protocol=SASL_SSL
      sasl.mechanism=PLAIN
      sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule
      required username\=“<API KEY>” password\=“<API SECRET>”;
      schema.registry.url=<SR ENDPOINT>
      basic.auth.credentials.source=USER_INFO
      schema.registry.basic.auth.user.info=<SR_KEY:SR_PASSWORD></programlisting>


Avro Producer and Consumer
---------------------------

.. include:: includes/client-example-schema-registry-3.rst

#. .. include:: includes/client-example-schema-registry-1.rst

#. .. include:: includes/client-example-schema-registry-2.rst


This Spring Boot application has the following two components:

  - Producer (``ProducerExample.java``)
  - Consumer (``ConsumerExample.java``)

Both components will be initialized during the Spring Boot application startup.
The producer writes Kafka data to a topic in your Kafka cluster. Each record has
a String key representing a username (for example, ``alice``) and a value of a
count, formatted as Avro object:

.. code-block:: text

   {"namespace": "io.confluent.examples.clients.cloud",
    "type": "record",
    "name": "DataRecordAvro",
    "fields": [
        {"name": "count", "type": "long"}
    ]
   }

Produce and Consume Records
~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Run the producer and consumer:

   .. code-block:: text

      ./startProducerConsumer.sh

   This command will build jar and executes ``spring-kafka`` powered producer
   and consumer. The consumer reads the same topic and prints data to the
   console. You should see:

   .. code-block:: text

         ...
         2020-02-13 14:41:57.924  INFO 44191 --- [ad | producer-1] i.c.e.c.c.springboot.ProducerExample     : Produced record to topic test partition 3 @ offset 20
         2020-02-13 14:41:57.927  INFO 44191 --- [ad | producer-1] i.c.e.c.c.springboot.ProducerExample     : Produced record to topic test partition 3 @ offset 21
         2020-02-13 14:41:57.927  INFO 44191 --- [ad | producer-1] i.c.e.c.c.springboot.ProducerExample     : Produced record to topic test partition 3 @ offset 22
         2020-02-13 14:41:57.927  INFO 44191 --- [ad | producer-1] i.c.e.c.c.springboot.ProducerExample     : Produced record to topic test partition 3 @ offset 23
         2020-02-13 14:41:57.928  INFO 44191 --- [ad | producer-1] i.c.e.c.c.springboot.ProducerExample     : Produced record to topic test partition 3 @ offset 24
         2020-02-13 14:41:57.928  INFO 44191 --- [ad | producer-1] i.c.e.c.c.springboot.ProducerExample     : Produced record to topic test partition 3 @ offset 25
         2020-02-13 14:41:57.928  INFO 44191 --- [ad | producer-1] i.c.e.c.c.springboot.ProducerExample     : Produced record to topic test partition 3 @ offset 26
         2020-02-13 14:41:57.929  INFO 44191 --- [ad | producer-1] i.c.e.c.c.springboot.ProducerExample     : Produced record to topic test partition 3 @ offset 27
         2020-02-13 14:41:57.929  INFO 44191 --- [ad | producer-1] i.c.e.c.c.springboot.ProducerExample     : Produced record to topic test partition 3 @ offset 28
         2020-02-13 14:41:57.930  INFO 44191 --- [ad | producer-1] i.c.e.c.c.springboot.ProducerExample     : Produced record to topic test partition 3 @ offset 29
         10 messages were produced to topic test
         ...

#. Verify the consumer received all the messages. You should see:

   .. code-block:: text

         ...
         2020-02-13 14:41:58.248  INFO 44191 --- [ntainer#0-0-C-1] i.c.e.c.c.springboot.ConsumerExample     : received alice {"count": 0}
         2020-02-13 14:41:58.248  INFO 44191 --- [ntainer#0-0-C-1] i.c.e.c.c.springboot.ConsumerExample     : received alice {"count": 1}
         2020-02-13 14:41:58.248  INFO 44191 --- [ntainer#0-0-C-1] i.c.e.c.c.springboot.ConsumerExample     : received alice {"count": 2}
         2020-02-13 14:41:58.248  INFO 44191 --- [ntainer#0-0-C-1] i.c.e.c.c.springboot.ConsumerExample     : received alice {"count": 3}
         2020-02-13 14:41:58.249  INFO 44191 --- [ntainer#0-0-C-1] i.c.e.c.c.springboot.ConsumerExample     : received alice {"count": 4}
         2020-02-13 14:41:58.249  INFO 44191 --- [ntainer#0-0-C-1] i.c.e.c.c.springboot.ConsumerExample     : received alice {"count": 5}
         2020-02-13 14:41:58.249  INFO 44191 --- [ntainer#0-0-C-1] i.c.e.c.c.springboot.ConsumerExample     : received alice {"count": 6}
         2020-02-13 14:41:58.249  INFO 44191 --- [ntainer#0-0-C-1] i.c.e.c.c.springboot.ConsumerExample     : received alice {"count": 7}
         2020-02-13 14:41:58.249  INFO 44191 --- [ntainer#0-0-C-1] i.c.e.c.c.springboot.ConsumerExample     : received alice {"count": 8}
         2020-02-13 14:41:58.249  INFO 44191 --- [ntainer#0-0-C-1] i.c.e.c.c.springboot.ConsumerExample     : received alice {"count": 9}

#. When you are done, press ``kbd:[CTRL + C]``.

#. View the :devx-examples:`producer|clients/cloud/java-springboot/src/main/java-springboot/io/confluent/examples/clients/cloud/springboot/kafka/ProducerExample.java` and :devx-examples:`consumer code|clients/cloud/java-springboot/src/main/java-springboot/io/confluent/examples/clients/cloud/springboot/kafka/ConsumerExample.java`.

Kafka Streams
-------------

The |kstreams| API reads the same topic and does a stateful sum aggregation,
also a rolling sum of the counts as it processes each record.

#. Run the |kstreams| application:

  .. code-block:: text

     ./startStreams.sh

  You should see:

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

#. When you are done, press ``kbd:[CTRL + C]``.

#. View the :devx-examples:`Kafka Streams code|clients/cloud/java-springboot/src/main/java-springboot/io/confluent/examples/clients/cloud/springboot/streams/SpringbootStreamsApplication.java`
