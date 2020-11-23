.. _quickstart-demos-replicator-schema-translation:

Replicator Schema Translation Example
=====================================

This |crep| example showcases the transfer of schemas stored in |sr-long| from one cluster to another.

========
Overview
========

|crep| features the ability to translate entries from a source |sr| to a destination |sr|.

This example provides a docker-compose environment with source and destination registries in which schemas are translated. In this example, you create an entry in the source |sr| and translate it to the destination.

The ``scripts`` directory provides examples of the operations that you must perform to prepare for the translation, as well as JSON |crep| configurations required.

=============
Prerequisites
=============

.. include:: ../../docs/includes/demo-validation-env.rst

===========
Run Example
===========

#. Clone the `confluentinc/examples <https://github.com/confluentinc/examples>`__ GitHub repository.

   .. sourcecode:: bash

     git clone https://github.com/confluentinc/examples

2. Change directory to the Schema Translation example.

   .. sourcecode:: bash

     cd examples/replicator-schema-translation

3. Start the entire example by running a single command that creates source and destination clusters automatically and adds a schema to the source |sr|. This takes less than 5 minutes to complete.

   .. sourcecode:: bash

      docker-compose up -d

4. Wait at least 2 minutes and then verify the example has completely started by checking the subjects in the source and destination |sr|.

   .. sourcecode:: bash

      # Source Schema Registry should show one subject, i.e., the output should be ["testTopic-value"]
      docker-compose exec connect curl http://srcSchemaregistry:8085/subjects

      # Destination Schema Registry should show no subjects, i.e., the output should be []
      docker-compose exec connect curl http://destSchemaregistry:8086/subjects

5. To prepare for schema translation, put the source |sr| in "READONLY" mode and the destination registry in "IMPORT" mode. Note that this works only when the destination |sr| has no registered subjects (as is true in this example), otherwise the import would fail with a message similar to "Cannot import since found existing subjects". 

   .. sourcecode:: bash

      docker-compose exec connect /etc/kafka/scripts/set_sr_modes_pre_translation.sh

   Your output should resemble:

   .. sourcecode:: bash

      Setting srcSchemaregistry to READONLY mode:
      {"mode":"READONLY"}
      Setting destSchemaregistry to IMPORT mode:
      {"mode":"IMPORT"}

6. Submit |crep| to perform the translation.

   .. sourcecode:: bash

      docker-compose exec connect /etc/kafka/scripts/submit_replicator.sh

   Your output should show the posted |crep| configuration. The key configuration that enables the schema translation is ``schema.subject.translator.class=io.confluent.connect.replicator.schemas.DefaultSubjectTranslator``

   .. sourcecode:: bash

      {"name":"testReplicator","config":{"connector.class":"io.confluent.connect.replicator.ReplicatorSourceConnector","topic.whitelist":"_schemas","topic.rename.format":"${topic}.replica","key.converter":"io.confluent.connect.replicator.util.ByteArrayConverter","value.converter":"io.confluent.connect.replicator.util.ByteArrayConverter","src.kafka.bootstrap.servers":"srcKafka1:10091","dest.kafka.bootstrap.servers":"destKafka1:11091","tasks.max":"1","confluent.topic.replication.factor":"1","schema.subject.translator.class":"io.confluent.connect.replicator.schemas.DefaultSubjectTranslator","schema.registry.topic":"_schemas","schema.registry.url":"http://destSchemaregistry:8086","name":"testReplicator"},"tasks":[],"type":"source"}

7. Verify the schema translation by revisiting the subjects in the source and destination Schema Registries.

   .. sourcecode:: bash

      # Source Schema Registry should show one subject, i.e., the output should be ["testTopic-value"]
      docker-compose exec connect curl http://srcSchemaregistry:8085/subjects
      
      # Destination Schema Registry should show one subject, i.e., the output should be ["testTopic.replica-value"]
      docker-compose exec connect curl http://destSchemaregistry:8086/subjects

8. To complete the example, reset both Schema Registries to ``READWRITE`` mode, this completes the migration process:

   .. sourcecode:: bash

      docker-compose exec connect /etc/kafka/scripts/set_sr_modes_post_translation.sh

.. tip:: This example shows a `one-time migration` of schemas across self-managed clusters. To configure a
         `continuous migration`, the last steps would be to set the origin (source) |sr| to READWRITE mode,
         and maintain the destination in IMPORT mode. Note that this would set up a "one-way" migration; that is,
         an active-to-passive |crep| setup.

========
Teardown
========

1. Stop the example, destroy all local components.

   .. sourcecode:: bash

      docker-compose down
      
=================
Suggested Reading
=================

* :ref:`schemaregistry_migrate`
* :ref:`sr-subjects-topics-primer`
* :ref:`replicator_quickstart`
* :ref:`replicator_failover`

* These sections in `Replicator Configuration Properties <https://docs.confluent.io/kafka-connect-replicator/current/configuration_options.html>`__:

  - `Source Topics <https://docs.confluent.io/kafka-connect-replicator/current/configuration_options.html#destination-data-conversion>`__
  - `Destination Topics <https://docs.confluent.io/kafka-connect-replicator/current/configuration_options.html#destination-topics>`__
  - `Schema Translation <https://docs.confluent.io/kafka-connect-replicator/current/configuration_options.html#schema-translation>`__

