.. _client-examples-rest-proxy:

|crest|: Example for |ak-tm|
============================

In this tutorial, you will use |crest-long| to
produce messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst



Prerequisites
-------------

Client
~~~~~~

- Docker version 17.06.1-ce
- Docker Compose version 1.25.4
- ``wget``

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for |crest|.

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

#. Get the :devx-cp-all-in-one:`cp-all-in-one-cloud docker-compose.yml|cp-all-in-one-cloud/docker-compose.yml` file,
   which runs |cp| in containers in your local host, and automatically configures them to
   connect to |ccloud|.

   .. codewithvars:: bash

      wget -O docker-compose.yml https://raw.githubusercontent.com/confluentinc/cp-all-in-one/|release_post_branch|/cp-all-in-one-cloud/docker-compose.yml

#. For the full |crest| configuration, view the |crest| section in the ``docker-compose.yml`` file which you just downloaded in the previous step.

   .. code-block:: text

      cat docker-compose.yml

Basic Producer and Consumer
---------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Since you are not going to use |sr| in this section, comment out the following lines in the ``docker-compose.yml`` file:

   .. code-block:: text

      #KAFKA_REST_SCHEMA_REGISTRY_URL: $SCHEMA_REGISTRY_URL
      #KAFKA_REST_CLIENT_BASIC_AUTH_CREDENTIALS_SOURCE: $BASIC_AUTH_CREDENTIALS_SOURCE
      #KAFKA_REST_CLIENT_SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO: $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO

#. Start the |crest| Docker container by running the following command:

   .. code-block:: text

       docker-compose up -d rest-proxy

#. View the |crest| logs and wait till you see the log message ``Server started, listening for requests`` to confirm it has started.

   .. code-block:: text

      docker-compose logs -f rest-proxy

#. Get the |ak| cluster ID that the |crest| is connected to.

   .. literalinclude:: ../cloud/rest-proxy/produce.sh
      :lines: 4-5

   Verify the parameter ``KAFKA_CLUSTER_ID`` has a valid value. For the example
   in this tutorial, it is shown as ``lkc-56ngz``, but it will differ in your
   output.

   .. code-block:: text

      echo $KAFKA_CLUSTER_ID

#. Create the |ak| topic ``test1`` using the ``AdminClient`` functionality of the |crest| API v3.

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
        "replication_factor": 0,
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

#. Produce three JSON messages to the topic, with key ``alice``, and values ``{"count":0}``, ``{"count":1}``, and ``{"count":2}``.

   .. literalinclude:: ../cloud/rest-proxy/produce.sh
      :lines: 14-18

   Verify your output resembles:

   .. code-block:: text

      {
        "offsets": [
          {
            "partition": 0,
            "offset": 0,
            "error_code": null,
            "error": null
          },
          {
            "partition": 0,
            "offset": 1,
            "error_code": null,
            "error": null
          },
          {
            "partition": 0,
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
        "instance_id": "ci1",
        "base_uri": "http://rest-proxy:8082/consumers/cg1/instances/ci1"
      }

#. Subscribe the consumer to topic ``test1``.

   .. literalinclude:: ../cloud/rest-proxy/consume.sh
      :lines: 10-13

#. Consume data using the base URL in the first response. Issue the curl command twice, sleeping 10 seconds in between—this is intentional due to https://github.com/confluentinc/kafka-rest/issues/432.

   .. literalinclude:: ../cloud/rest-proxy/consume.sh
      :lines: 17-25

   Verify your output resembles:

   .. code-block:: text

      []
      [
        {
          "topic": "test1",
          "key": "alice",
          "value": {
            "count": 0
          },
          "partition": 0,
          "offset": 0
        },
        {
          "topic": "test1",
          "key": "alice",
          "value": {
            "count": 1
          },
          "partition": 0,
          "offset": 1
        },
        {
          "topic": "test1",
          "key": "alice",
          "value": {
            "count": 2
          },
          "partition": 0,
          "offset": 2
        }
      ]
      
#. Delete the consumer instance to clean up its resources

   .. literalinclude:: ../cloud/rest-proxy/consume.sh
      :lines: 28-30

#. View the :devx-examples:`consumer code|clients/cloud/rest-proxy/consume.sh`.

Stop |crest|
~~~~~~~~~~~~

#. Stop Docker by running the following command:

   .. code-block:: text

       docker-compose down


Avro and Confluent Cloud Schema Registry
-----------------------------------------

.. include:: includes/schema-registry-scenario-explain.rst

#. .. include:: includes/client-example-schema-registry-1.rst

#. .. include:: includes/client-example-vpc.rst

#. .. include:: includes/schema-registry-java.rst

#. .. include:: includes/client-example-schema-registry-2-java.rst

#. Regenerate a file of ENV variables used by Docker to set the bootstrap
   servers and security configuration.

   .. code-block:: text

      ../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.confluent/java.config

#. Source the regenerated file of ``ENV`` variables.

   .. code-block:: text

      source ./delta_configs/env.delta

Produce Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Since you are now going to use |sr| in this section, uncomment the following lines in the ``docker-compose.yml`` file:

   .. code-block:: text

      KAFKA_REST_SCHEMA_REGISTRY_URL: $SCHEMA_REGISTRY_URL
      KAFKA_REST_CLIENT_BASIC_AUTH_CREDENTIALS_SOURCE: $BASIC_AUTH_CREDENTIALS_SOURCE
      KAFKA_REST_CLIENT_SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO: $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO

#. Start the |crest| Docker container by running the following command:

   .. code-block:: text

       docker-compose up -d rest-proxy

#. View the |crest| logs and wait till you see the log message ``Server started, listening for requests`` to confirm it has started.

   .. code-block:: text

      docker-compose logs -f rest-proxy

#. Get the |ak| cluster ID that the |crest| is connected to.

   .. literalinclude:: ../cloud/rest-proxy/produce-ccsr.sh
      :lines: 11-12

   Verify the parameter ``KAFKA_CLUSTER_ID`` has a valid value. For the example
   in this tutorial, it is shown as ``lkc-56ngz``, but it will differ in your
   output.

#. Create the |ak| topic ``test2`` using the ``AdminClient`` functionality of the |crest| API v3.

   .. literalinclude:: ../cloud/rest-proxy/produce-ccsr.sh
      :lines: 15-18

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
        "replication_factor": 0,
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

#. Register a new Avro schema for topic ``test2`` with the |ccloud| |sr|.

   .. literalinclude:: ../cloud/rest-proxy/produce-ccsr.sh
      :lines: 21-22

   Verify the output shows the new schema id:

   .. code-block:: text

      {"id":100001}

#. Set the variable ``schemaid`` to the value of the schema ID.

   .. literalinclude:: ../cloud/rest-proxy/produce-ccsr.sh
      :lines: 24

#. Produce three Avro messages to the topic, with values ``{"count":0}``, ``{"count":1}``, and ``{"count":2}``. Notice that the request body includes the schema ID.

   .. literalinclude:: ../cloud/rest-proxy/produce-ccsr.sh
      :lines: 27-31

   Verify your output resembles:

   .. code-block:: text

      {
        "offsets": [
          {
            "partition": 4,
            "offset": 0,
            "error_code": null,
            "error": null
          },
          {
            "partition": 4,
            "offset": 1,
            "error_code": null,
            "error": null
          },
          {
            "partition": 4,
            "offset": 2,
            "error_code": null,
            "error": null
          }
        ],
        "key_schema_id": null,
        "value_schema_id": 100001
      }

#. View the :devx-examples:`producer Avro code|clients/cloud/rest-proxy/produce-ccsr.sh`.

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

#. Subscribe the consumer to topic ``test2``.

   .. literalinclude:: ../cloud/rest-proxy/consume-ccsr.sh
      :lines: 10-13

#. Consume data using the base URL in the first response. Issue the curl command twice, sleeping 10 seconds in between—this is intentional due to https://github.com/confluentinc/kafka-rest/issues/432.

   .. literalinclude:: ../cloud/rest-proxy/consume-ccsr.sh
      :lines: 17-25

   Verify your output resembles:

   .. code-block:: text

      []
      [
        {
          "topic": "test2",
          "key": null,
          "value": {
            "count": 0
          },
          "partition": 0,
          "offset": 0
        },
        {
          "topic": "test2",
          "key": null,
          "value": {
            "count": 1
          },
          "partition": 0,
          "offset": 1
        },
        {
          "topic": "test2",
          "key": null,
          "value": {
            "count": 2
          },
          "partition": 0,
          "offset": 2
        }
      ]
      
#. Delete the consumer instance to clean up its resources

   .. literalinclude:: ../cloud/rest-proxy/consume-ccsr.sh
      :lines: 28-30

#. View the :devx-examples:`consumer Avro code|clients/cloud/rest-proxy/consume-ccsr.sh`.


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

      {"subject":"test2-value","version":1,"id":100001,"schema":"[{\"type\":\"record\",\"name\":\"countInfo\",\"fields\":[{\"name\":\"count\",\"type\":\"long\"}]}]"}

Stop |crest|
~~~~~~~~~~~~

#. Stop Docker by running the following command:

   .. code-block:: text

       docker-compose down
