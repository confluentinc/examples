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

1. Clone the `examples GitHub repository <https://github.com/confluentinc/examples>`__.

   .. sourcecode:: bash

     git clone https://github.com/confluentinc/examples

2. Change directory to the Schema Translation demo.

   .. sourcecode:: bash

     cd examples/replicator-schema-translation

3. Start the entire demo by running a single command that creates source and destination clusters automatically and adds a schema to the source cluster |sr|. This takes less than 5 minutes to complete.

   .. sourcecode:: bash

      docker-compose up -d

   Verify the demo has completely started by using Google Chrome to view the Schema Registries. The source cluster is at: ``http://localhost:8085/subjects`` (you should see: ``["testTopic-value"]``) and the destination cluster is at: ``http://localhost:8086/subjects`` (you should see: ``[]``).

4. To prepare for schema translation, you must put the source cluster registry in "READONLY" mode and the destination registry in "IMPORT" mode.

   .. sourcecode:: bash

      docker-compose exec connect /etc/kafka/scripts/set_sr_modes_pre_translation.sh

   Your output should resemble:

   .. sourcecode:: json

      {"mode":"READONLY"}{"mode":"IMPORT"}

5. Now we submit Replicator to perform the translation.

   .. sourcecode:: bash

      $ docker-compose exec connect /etc/kafka/scripts/submit_replicator.sh

   This should produce:

   .. sourcecode:: bash

      {"name":"testReplicator","config":{"connector.class":"io.confluent.connect.replicator.ReplicatorSourceConnector","topic.whitelist":"_schemas","topic.rename.format":"${topic}.replica","key.converter":"io.confluent.connect.replicator.util.ByteArrayConverter","value.converter":"io.confluent.connect.replicator.util.ByteArrayConverter","src.kafka.bootstrap.servers":"srcKafka1:10091","dest.kafka.bootstrap.servers":"destKafka1:11091","tasks.max":"1","confluent.topic.replication.factor":"1","schema.subject.translator.class":"io.confluent.connect.replicator.schemas.DefaultSubjectTranslator","schema.registry.topic":"_schemas","schema.registry.url":"http://destSchemaregistry:8086","name":"testReplicator"},"tasks":[],"type":"source"}

6. Now verify the translation by revisiting the Schema Registries at: http://localhost:8085/subjects and: http://localhost:8086/subjects. They should both now list schemas with the destination cluster showing ``["testTopic.replica-value"]``:

7. To complete the demo return both clusters to ``READWRITE`` mode:

   .. sourcecode:: bash

      docker-compose exec connect /etc/kafka/scripts/set_sr_modes_post_translation.sh

========
Teardown
========

1. Stop the demo, destroy all local components.

   .. sourcecode:: bash

      docker-compose down

