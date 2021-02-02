.. _client-examples-java-springboot:

Java Spring Boot: Code Example for |ak-tm|
==========================================

In this tutorial, you will run a Java Spring Boot client application that
produces messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst

Prerequisites
-------------

Client
~~~~~~

-  Java 1.8 or higher to run the demo application.


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


Avro and Confluent Cloud Schema Registry
----------------------------------------

.. include:: includes/producer-consumer-description.rst

#. .. include:: includes/client-example-schema-registry-1.rst

#. .. include:: includes/client-example-vpc.rst

#. .. include:: includes/schema-registry-java.rst

#. .. include:: includes/client-example-schema-registry-2-java.rst


Produce and Consume Records
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This Spring Boot application has the following two components: :devx-examples:`Producer|clients/cloud/java-springboot/src/main/java/io/confluent/examples/clients/cloud/springboot/kafka/ProducerExample.java` and :devx-examples:`Consumer|clients/cloud/java-springboot/src/main/java/io/confluent/examples/clients/cloud/springboot/kafka/ConsumerExample.java` that are initialized during the Spring Boot application startup.
The producer writes Kafka data to a topic in your |ak| cluster. Each record has
a String key representing a username (for example, ``alice``) and a value of a
count, formatted with the Avro schema :devx-examples:`DataRecordAvro.avsc|clients/cloud/java-springboot/src/main/avro/DataRecordAvro.avsc`

.. literalinclude:: ../cloud/java-springboot/src/main/avro/DataRecordAvro.avsc

#. Run the producer and consumer with the following command. It builds the jar and executes ``spring-kafka`` powered producer and consumer.

   .. code-block:: text

      ./startProducerConsumer.sh

#. Verify the producer sent all the messages. You should see:

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

#. When you are done, press ``CTRL-C``.

#. View the :devx-examples:`producer code|clients/cloud/java-springboot/src/main/java/io/confluent/examples/clients/cloud/springboot/kafka/ProducerExample.java` and :devx-examples:`consumer code|clients/cloud/java-springboot/src/main/java/io/confluent/examples/clients/cloud/springboot/kafka/ConsumerExample.java`.

Kafka Streams
~~~~~~~~~~~~~

The |kstreams| API reads from the same topic and does a rolling count and stateful sum aggregation as it processes each record.

#. Run the |kstreams| application:

   .. code-block:: text

      ./startStreams.sh

#. Verify that you see the output:

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

#. When you are done, press ``CTRL-C``.

#. View the :devx-examples:`Kafka Streams code|clients/cloud/java-springboot/src/main/java/io/confluent/examples/clients/cloud/springboot/streams/SpringbootStreamsApplication.java`.

Suggested Resources
-------------------

* `Blog posts <https://www.confluent.io/blog/tag/spring>`__
* `Podcasts <https://developer.confluent.io/podcast/topic/spring>`__
* `Videos <https://www.youtube.com/playlist?list=PLa7VYi0yPIH26-ppF0Gcsx-YVQQbNjDEt>`__
