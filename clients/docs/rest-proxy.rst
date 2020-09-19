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

       docker-compose up -d rest-proxy

#. Verify REST Proxy has started.  View the |crest| logs in Docker and wait till you see the log message ``Server started, listening for requests``.

   .. code-block:: text

      docker-compose logs rest-proxy

Basic Producer and Consumer
---------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Get the |ak| cluster ID that the |crest| is connected to.

   .. literalinclude:: ../cloud/rest-proxy/produce.sh
      :lines: 4-5

   Verify the parameter ``KAFKA_CLUSTER_ID`` has a valid value. For the example
   in this tutorial, it is shown as ``lkc-56ngz``, but it will differ in your
   output.

   .. code-block:: text

      echo $KAFKA_CLUSTER_ID

#. Create the |ak| topic ``test1`` using the ``AdminClient`` functionality of the |crest| API v3. If |crest| is backed to |ccloud|, configure the replication factor to ``3``.

   .. literalinclude:: ../cloud/rest-proxy/produce.sh
      :lines: 8-11

   Verify your output resembles:

   .. code-block:: text

      {
        "kind": "KafkaTopic",
        "metadata": {
          "self": "http://rest-proxy:8082/v3/clusters/lkc-56ngz/topics/test1",
          "resource_name": "crn:///kafka=lkc-56ngz/topic=test1"
        },
        "cluster_id": "lkc-56ngz",
        "topic_name": "test2",
        "is_internal": false,
        "replication_factor": 3,
        "partitions": {
          "related": "http://rest-proxy:8082/v3/clusters/lkc-56ngz/topics/test2/partitions"
        },
        "configs": {
          "related": "http://rest-proxy:8082/v3/clusters/lkc-56ngz/topics/test2/configs"
        },
        "partition_reassignments": {
          "related": "http://rest-proxy:8082/v3/clusters/lkc-56ngz/topics/test1/partitions/-/reassignment"
        }
      }

#. Produce 3 messages to the topic ``test1``: ``{"count":0}``, ``{"count":1}``, and ``{"count":2}``.

   .. literalinclude:: ../cloud/rest-proxy/produce.sh
      :lines: 14-18

   Verify your output resembles:

   .. code-block:: text

      {
        "offsets": [
          {
            "partition": 3,
            "offset": 0,
            "error_code": null,
            "error": null
          },
          {
            "partition": 3,
            "offset": 1,
            "error_code": null,
            "error": null
          },
          {
            "partition": 3,
            "offset": 2,
            "error_code": null,
            "error": null
          }
        ],
        "key_schema_id": null,
        "value_schema_id": null
      }
      
#. View the :devx-examples:`producer code|clients/cloud/rest-proxy/produce.sh`.

Consume Records
~~~~~~~~~~~~~~~

#. Create a consumer ``ci1`` belonging to consumer group ``cg1``.  Specify ``auto.offset.reset`` to be ``earliest`` so it starts at the beginning of the topic.

   .. literalinclude:: ../cloud/rest-proxy/consume.sh
      :lines: 4-7

   Verify your output resembles:

   .. code-block:: text

      {
        "instance_id": "ci2",
        "base_uri": "http://rest-proxy:8082/consumers/cg1/instances/ci1"
      }

#. Subscribe the consumer to topic ``test1``.

   .. literalinclude:: ../cloud/rest-proxy/consume.sh
      :lines: 10-13

#. Consume data using the base URL in the first response. It is intentional to issue this command twice due to https://github.com/confluentinc/kafka-rest/issues/432, sleeping 10 seconds in between.

   .. literalinclude:: ../cloud/rest-proxy/consume.sh
      :lines: 17-25

   Verify your output resembles:

   .. code-block:: text

      []
      [
        {
          "topic": "test1",
          "key": null,
          "value": {
            "count": 0
          },
          "partition": 3,
          "offset": 0
        },
        {
          "topic": "test1",
          "key": null,
          "value": {
            "count": 1
          },
          "partition": 3,
          "offset": 1
        },
        {
          "topic": "test1",
          "key": null,
          "value": {
            "count": 2
          },
          "partition": 3,
          "offset": 2
        }
      ]
      
#. Delete the consumer instance to clean up its resources

   .. literalinclude:: ../cloud/rest-proxy/consume.sh
      :lines: 28-30

#. View the :devx-examples:`consumer code|clients/cloud/rest-proxy/consume.sh`.


Avro and Confluent Cloud Schema Registry
-----------------------------------------

.. include:: includes/schema-registry-scenario-explain.rst

#. .. include:: includes/client-example-schema-registry-1.rst

#. .. include:: includes/client-example-vpc.rst

#. .. include:: includes/schema-registry-java.rst

#. .. include:: includes/client-example-schema-registry-2-java.rst


Produce Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Get the |ak| cluster ID that the |crest| is connected to.

   .. literalinclude:: ../cloud/rest-proxy/produce-ccsr.sh
      :lines: 9-10

   Verify the parameter ``KAFKA_CLUSTER_ID`` has a valid value. For the example
   in this tutorial, it is set to ``lkc-56ngz``, but it will be different in your
   environment.

#. Create the |ak| topic ``test2`` using the ``AdminClient`` functionality of the |crest| API v3. If |crest| is backed to |ccloud|, configure the replication factor to ``3``.

   .. literalinclude:: ../cloud/rest-proxy/produce-ccsr.sh
      :lines: 13-16

   Verify your output resembles:

   .. code-block:: text

      {
        "kind": "KafkaTopic",
        "metadata": {
          "self": "http://rest-proxy:8082/v3/clusters/lkc-56ngz/topics/test2",
          "resource_name": "crn:///kafka=lkc-56ngz/topic=test2"
        },
        "cluster_id": "lkc-56ngz",
        "topic_name": "test2",
        "is_internal": false,
        "replication_factor": 3,
        "partitions": {
          "related": "http://rest-proxy:8082/v3/clusters/lkc-56ngz/topics/test2/partitions"
        },
        "configs": {
          "related": "http://rest-proxy:8082/v3/clusters/lkc-56ngz/topics/test2/configs"
        },
        "partition_reassignments": {
          "related": "http://rest-proxy:8082/v3/clusters/lkc-56ngz/topics/test2/partitions/-/reassignment"
        }
      }

#. Produce a message ``{"user":{"userid": 1}}`` to the topic ``test2``.

   .. literalinclude:: ../cloud/rest-proxy/produce-ccsr.sh
      :lines: 19-23

   Verify your output resembles:

   .. code-block:: text

      {
        "offsets": [
          {
            "partition": 2,
            "offset": 0,
            "error_code": null,
            "error": null
          }
        ],
        "key_schema_id": null,
        "value_schema_id": null
      }

#. View the :devx-examples:`producer code|clients/cloud/rest-proxy/produce-ccsr.sh`.

Consume Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Create a consumer ``ci2`` belonging to consumer group ``cg2``.  Specify ``auto.offset.reset`` to be ``earliest`` so it starts at the beginning of the topic.

   .. literalinclude:: ../cloud/rest-proxy/consume-ccsr.sh
      :lines: 4-7

   Verify your output resembles:

   .. code-block:: text

      {
        "instance_id": "ci2",
        "base_uri": "http://rest-proxy:8082/consumers/cg2/instances/ci2"
      }

#. Subscribe the consumer to topic ``test1``.

   .. literalinclude:: ../cloud/rest-proxy/consume-ccsr.sh
      :lines: 10-13

#. Consume data using the base URL in the first response. It is intentional to issue this command twice due to https://github.com/confluentinc/kafka-rest/issues/432, sleeping 10 seconds in between.

   .. literalinclude:: ../cloud/rest-proxy/consume-ccsr.sh
      :lines: 17-25

   Verify your output resembles:

   .. code-block:: text

      []
      [
        {
          "topic": "test1",
          "key": null,
          "value": {
            "count": 0
          },
          "partition": 2,
          "offset": 0
        }
      ]
      
#. Delete the consumer instance to clean up its resources

   .. literalinclude:: ../cloud/rest-proxy/consume-ccsr.sh
      :lines: 28-30

#. View the :devx-examples:`consumer code|clients/cloud/rest-proxy/consume-ccsr.sh`.


|ccloud| |sr|
~~~~~~~~~~~~~

#. View the schema subjects registered in |sr-ccloud|. In the following output, substitute values for ``<SR API KEY>``, ``<SR API SECRET>``, and ``<SR ENDPOINT>``.

   .. code-block:: text

      curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects

#. Verify that the subject ``test2-value`` exists.


   .. code-block:: text

      ["test2-value"]

#. View the schema information for subject `test2-value`. In the following output, substitute values for ``<SR API KEY>``, ``<SR API SECRET>``, and ``<SR ENDPOINT>``.

   .. code-block:: text

      curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects/test2-value/versions/1

#. Verify the schema information for subject ``test2-value``.

   .. code-block:: text

      {"subject":"test2-value","version":1,"id":100001,"schema":"{\"name\":\"io.confluent.examples.clients.cloud.DataRecordAvro\",\"type\":\"record\",\"fields\":[{\"name\":\"count\",\"type\":\"long\"}]}"}

