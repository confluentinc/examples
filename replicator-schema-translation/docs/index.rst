.. _quickstart-demos-replicator-schema-translation:

Replicator Schema Translation Demo
==================================

This |crep| demo showcases the transfer of schemas stored in |sr-long| from one cluster to another.

========
Overview
========

|crep| features the ability to translate entries from a source |sr| to a destination |sr|.

This demo provides a docker-compose environment with source and destination registries in which schemas are translated. In this demo, you create an entry in the source |sr| and translate it to the destination.

The ``scripts`` directory provides examples of the operations that you must perform to prepare for the translation, as well as JSON |crep| configurations required.

=============
Prerequisites
=============

**Demo validated with:**

-  |cp| |version|
-  Docker 19.03.2
-  Docker-compose 1.24.1
-  Java version 1.8.0_162
-  MacOS 10.12

============
Run the Demo
============

1. Clone the `examples GitHub repository <https://github.com/confluentinc/examples>`__.

   .. sourcecode:: bash

     git clone https://github.com/confluentinc/examples

2. Change directory to the Schema Translation demo.

   .. sourcecode:: bash

     cd examples/replicator-schema-translation

3. Start the entire demo by running a single command that creates source and destination clusters automatically and adds a schema to the source |sr|. This takes less than 5 minutes to complete.

   .. sourcecode:: bash

      docker-compose up -d

4. Wait at least 2 minutes and then verify the demo has completely started by checking the subjects in the source and destination |sr|.

   .. sourcecode:: bash

      # Source Schema Registry should show one subject, i.e., the output should be ["testTopic-value"]
      docker-compose exec connect curl http://srcSchemaregistry:8085/subjects

      # Destination Schema Registry should show no subjects, i.e., the output should be []
      docker-compose exec connect curl http://destSchemaregistry:8086/subjects

5. To prepare for schema translation, put the source |sr| in "READONLY" mode and the destination registry in "IMPORT" mode. Note that this works only when the destination |sr| has no registered subjects (as is true in this demo), otherwise the import would fail with a message similar to "Cannot import since found existing subjects". 

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

   Your output should show the posted |crep| configuration. The key configuration that enables the schema translation is `schema.subject.translator.class=io.confluent.connect.replicator.schemas.DefaultSubjectTranslator`

   .. sourcecode:: bash

      {"name":"testReplicator","config":{"connector.class":"io.confluent.connect.replicator.ReplicatorSourceConnector","topic.whitelist":"_schemas","topic.rename.format":"${topic}.replica","key.converter":"io.confluent.connect.replicator.util.ByteArrayConverter","value.converter":"io.confluent.connect.replicator.util.ByteArrayConverter","src.kafka.bootstrap.servers":"srcKafka1:10091","dest.kafka.bootstrap.servers":"destKafka1:11091","tasks.max":"1","confluent.topic.replication.factor":"1","schema.subject.translator.class":"io.confluent.connect.replicator.schemas.DefaultSubjectTranslator","schema.registry.topic":"_schemas","schema.registry.url":"http://destSchemaregistry:8086","name":"testReplicator"},"tasks":[],"type":"source"}

7. Verify the schema translation by revisiting the subjects in the source and destination Schema Registries.

   .. sourcecode:: bash

      # Source Schema Registry should show one subject, i.e., the output should be ["testTopic-value"]
      docker-compose exec connect curl http://srcSchemaregistry:8085/subjects
      
      # Destination Schema Registry should show one subject, i.e., the output should be ["testTopic.replica-value"]
      docker-compose exec connect curl http://destSchemaregistry:8086/subjects

8. To complete the demo, reset both Schema Registries to ``READWRITE`` mode:

   .. sourcecode:: bash

      docker-compose exec connect /etc/kafka/scripts/set_sr_modes_post_translation.sh
      
.. tip:: This demo shows a `one-time migration` of schemas across self-managed clusters. To configure a
         `continuous migration`, the last steps would be to keep the origin (source) |sr| in READONLY mode, and set the destination
         to READWRITE. Note that this only works for a "one-way" migration; that is, an active-to-passive
         |crep| setup. This is especially helpful if configure topic names to be different on the destination,
         using the translation configuration, ``topic.rename.format`` (described in :ref:`Replicator configuration destination topics <rep-destination-topics>`),
         to rename the subjects in the schemas accordingly as it migrates them.

========
Teardown
========

1. Stop the demo, destroy all local components.

   .. sourcecode:: bash

      docker-compose down
      
=================
Suggested Reading
=================

* :ref:`schemaregistry_migrate`
* :ref:`schemaregistry_config`
* :ref:`replicator_quickstart`

* These sections in :ref:`Replicator Configuration Options<connect_replicator_config_options>`: 

  - :ref:`rep-source-topics`
  - :ref:`rep-destination-topics`
  - :ref:`schema_translation`
