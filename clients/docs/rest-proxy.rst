.. _client-examples-rest-proxy:

|crest-long|
============

In this tutorial, you will use |crest-long| to
produce messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst



Prerequisites
-------------

Client
~~~~~~

-  Docker

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for KSQL Datagen.

   .. code-block:: text

      cd clients/cloud/rest-proxy/

#. .. include:: includes/client-example-create-file-java.rst

#. Generate a file of ENV variables used by Docker to set the bootstrap
   servers and security configuration.

   .. code-block:: text

      ../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.confluent/java.config

#. Source the generated file of ``ENV`` variables.

   .. code-block:: text

      source ./delta_configs/env.delta

#. Start Docker by running the following command:

   .. code-block:: text

       docker-compose up -d

#. Verify REST Proxy has started.  View the |crest| logs in Docker and wait till you see the log message ``Server started, listening for requests``.

   .. code-block:: text

      docker-compose logs rest-proxy

Basic Producer and Consumer
---------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Get the |ak| cluster id that the |crest| is connected to.

   .. code-block:: text

      KAFKA_CLUSTER_ID=$(docker-compose exec rest-proxy curl -X GET \
         "http://localhost:8082/v3/clusters/" | jq -r ".data[0].cluster_id")

#. Create the |ak| topic ``test1`` using the ``AdminClient`` functionality of the |crest| API v3. If |crest| is backed to |ccloud|, configure the replication factor to ``3``.

   .. code-block:: text

      docker-compose exec rest-proxy curl -X POST \
           -H "Content-Type: application/json" \
           -d "{\"topic_name\":\"test1\",\"partitions_count\":6,\"replication_factor\":3,\"configs\":[]}" \
           "http://localhost:8082/v3/clusters/${KAFKA_CLUSTER_ID}/topics"

#. Produce a message ``{"foo":"bar"}`` to the topic ``test1``.

   .. code-block:: text

      docker-compose exec rest-proxy curl -X POST \
           -H "Content-Type: application/vnd.kafka.json.v2+json" \
           -H "Accept: application/vnd.kafka.v2+json" \
           --data '{"records":[{"value":{"foo":"bar"}}]}' \
           "http://localhost:8082/topics/test1

#. View the :devx-examples:`producer code|clients/cloud/rest-proxy/producer.sh`.

Consume Records
~~~~~~~~~~~~~~~

#. Create a consumer ``ci1`` belonging to consumer group ``cg1``.  Specify ``auto.offset.reset`` to be ``earliest`` so it starts at the beginning of the topic.

   .. code-block:: text

      docker-compose exec rest-proxy curl -X POST \
           -H "Content-Type: application/vnd.kafka.v2+json" \
           --data '{"name": "ci1", "format": "json", "auto.offset.reset": "earliest"}' \
           http://localhost:8082/consumers/cg1

#. Subscribe the consumer to topic ``test1``.

   .. code-block:: text

      docker-compose exec rest-proxy curl -X POST \
           -H "Content-Type: application/vnd.kafka.v2+json" \
           --data '{"topics":["'"$topic_name"'"]}' \
           http://localhost:8082/consumers/cg1/instances/ci1/subscription

#. Consume data using the base URL in the first response. It is intentional to issue this command twice due to https://github.com/confluentinc/kafka-rest/issues/432, sleeping 10 seconds in between.

   .. code-block:: text

      docker-compose exec rest-proxy curl -X GET \
           -H "Accept: application/vnd.kafka.json.v2+json" \
           http://localhost:8082/consumers/cg1/instances/ci1/records
      
      sleep 10
      
      docker-compose exec rest-proxy curl -X GET \
           -H "Accept: application/vnd.kafka.json.v2+json" \
           http://localhost:8082/consumers/cg1/instances/ci1/records
      
#. Delete the consumer instance to clean up its resources

   .. code-block:: text

      docker-compose exec rest-proxy curl -X DELETE \
           -H "Content-Type: application/vnd.kafka.v2+json" \
           http://localhost:8082/consumers/cg1/instances/ci1

#. View the :devx-examples:`consumer code|clients/cloud/rest-proxy/consumer.sh`.
