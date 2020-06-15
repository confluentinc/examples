.. _cloud-etl:
  
.. toctree::
    :maxdepth: 2

Cloud ETL Demo
==============

As enterprises move more and more of their applications to the cloud, they are also moving their on-prem ETL (extract, transform, load) pipelines to the cloud, as well as building new ones.
This demo showcases a cloud ETL solution leveraging all fully-managed services on `Confluent Cloud <https://confluent.cloud>`__.

.. figure:: images/cloud-etl.png
   :alt: image

There are many powerful use cases for these real-time cloud ETL pipelines, and this demo showcases one such use case—a log ingestion pipeline that spans multiple cloud providers.
Using |ccloud| CLI, the demo creates a source connector that reads data from either an AWS Kinesis stream or AWS RDS PostgreSQL database into |ccloud|.
Then it creates a |ccloud| ksqlDB application that processes that data.
Finally, a sink connector writes the output data into cloud storage in the provider of your choice (one of GCP GCS, AWS S3, or Azure Blob).

.. figure:: images/topology.png
   :alt: image

The end result is an event streaming ETL, running 100% in the cloud, spanning multiple cloud providers.
This enables you to:

*  Build business applications on a full event streaming platform
*  Span multiple cloud providers (AWS, GCP, Azure) and on-prem datacenters
*  Use Kafka to aggregate data into a single source of truth
*  Harness the power of `ksqlDB <https://www.confluent.io/product/ksql/>`__ for stream processing

.. tip:: For more information about building a cloud ETL pipeline on |ccloud|, see this
         `blog post <https://www.confluent.io/blog/build-a-cloud-etl-pipeline-with-confluent-cloud/>`__.

.. include:: ../../ccloud/docs/includes/ccloud-promo-code.rst

========================
End-to-end Streaming ETL
========================

This demo showcases an entire end-to-end cloud ETL deployment, built for 100% cloud services:

-  Cloud source connectors: writes data to Kafka topics in |ccloud| from a cloud service, one of:

   - :ref:`cc_kinesis-source`
   - :ref:`cc_postgresql-source`

-  Cloud sink connectors: writes data from Kafka topics in |ccloud| to cloud storage, one of:

   - :ref:`cc_azure_blob_sink`
   - :ref:`cc_gcs_connect_sink`
   - :ref:`cc_s3_connect_sink`

-  `Confluent Cloud ksqlDB <https://docs.confluent.io/current/quickstart/cloud-quickstart/ksql.html>`__ : streaming SQL engine that enables real-time data processing against Kafka

-  :ref:`Confluent Cloud Schema Registry <cloud-install-schema-registry>`: centralized management of schemas and compatibility checks as schemas evolve 


Data Flow
---------

The data set is a stream of log messages, which in this demo is mock data captured in :devx-examples:`eventlogs.json|cloud-etl/eventlogs.json`.
It resembles this:

.. sourcecode:: bash

   {"eventSourceIP":"192.168.1.1","eventAction":"Upload","result":"Pass","eventDuration":3}
   {"eventSourceIP":"192.168.1.1","eventAction":"Create","result":"Pass","eventDuration":2}
   {"eventSourceIP":"192.168.1.1","eventAction":"Delete","result":"Fail","eventDuration":5}
   {"eventSourceIP":"192.168.1.2","eventAction":"Upload","result":"Pass","eventDuration":1}
   {"eventSourceIP":"192.168.1.2","eventAction":"Create","result":"Pass","eventDuration":3}


+-----------------------+-----------------------+-----------------------+
| Component             | Consumes From         | Produces To           |
+=======================+=======================+=======================+
| Kinesis/PostgreSQL    | Kinesis stream or     | Kafka topic           |
| source connector      | RDS PostgreSQL table  | ``eventlogs``         |
+-----------------------+-----------------------+-----------------------+
| ksqlDB                | ``eventlogs``         | ksqlDB streams and    |
|                       |                       | tables                |
+-----------------------+-----------------------+-----------------------+
| GCS/S3/Blob           | ksqlDB tables         | GCS/S3/Blob           |
| sink connector        | ``COUNT_PER_SOURCE``, |                       |
|                       | ``SUM_PER_SOURCE``    |                       |
+-----------------------+-----------------------+-----------------------+

=======
Caution
=======

This ``cloud-etl`` demo uses real cloud resources, including that of |ccloud|, AWS Kinesis or RDS PostgreSQL, and one of the cloud storage providers.
To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done running it.

=============
Prerequisites
=============

Cloud services
--------------

-  `Confluent Cloud cluster <https://confluent.cloud>`__
-  Access to AWS and (optional) GCP or Azure

Local Tools
-----------

-  `Confluent Cloud CLI <https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html#step-2-install-the-ccloud-cli>`__ v1.7.0 or later
-  ``gsutil`` CLI, properly initialized with your credentials: (optional) if destination is GCP GCS
-  ``aws`` CLI, properly initialized with your credentials: used for AWS Kinesis or RDS PostgreSQL, and (optional) if destination is AWS S3
-  ``az`` CLI, properly initialized with your credentials: (optional) if destination is Azure Blob storage
-  ``jq``
-  ``curl``
-  ``timeout``
-  ``python``
-  Download `Confluent Platform <https://www.confluent.io/download/>`__ |release|: for more advanced Confluent CLI functionality (optional)

============
Run the Demo
============

Setup
-----

Because this demo interacts with real resources in Kinesis or RDS PostgreSQL, a destination storage service, and |ccloud|, you must set up some initial parameters to communicate with these services.

#. This demo creates a new |ccloud| environment with required resources to run this demo. As a reminder, this demo uses real |ccloud| resources and you may incur charges so carefully evaluate the cost of resources before launching the demo.

#. Clone the `examples GitHub repository <https://github.com/confluentinc/examples>`__ and check out the :litwithvars:`|release|-post` branch.

   .. codewithvars:: bash

     git clone https://github.com/confluentinc/examples
     cd examples
     git checkout |release|-post

#. Change directory to the ``cloud-etl`` demo.

   .. sourcecode:: bash

     cd cloud-etl


#. Modify the demo configuration file at :devx-examples:`config/demo.cfg|cloud-etl/config/demo.cfg`. Set the proper credentials and parameters for the source:

   - AWS Kinesis

     - ``DATA_SOURCE='kinesis'``
     - ``KINESIS_STREAM_NAME``
     - ``KINESIS_REGION``
     - ``AWS_PROFILE``

   - AWS RDS (PostgreSQL)

     - ``DATA_SOURCE='rds'``
     - ``DB_INSTANCE_IDENTIFIER``
     - ``RDS_REGION``
     - ``AWS_PROFILE``

#. In the same demo configuration file, set the required parameters for the destination cloud storage provider:

   - GCP GCS

     - ``DESTINATION_STORAGE='gcs'``
     - ``GCS_CREDENTIALS_FILE``
     - ``GCS_BUCKET``

   - AWS S3

     - ``DESTINATION_STORAGE='s3'``
     - ``S3_PROFILE``
     - ``S3_BUCKET``

   - Azure Blob

     - ``DESTINATION_STORAGE='az'``
     - ``AZBLOB_STORAGE_ACCOUNT``
     - ``AZBLOB_CONTAINER``

Run
---

#. Log in to |ccloud| with the command ``ccloud login``, and use your |ccloud| username and password.

   .. code:: shell

      ccloud login --url https://confluent.cloud

#. Run the demo. This will take several minutes to complete as it creates new resources in |ccloud| and services in other cloud providers.

   .. code:: bash

      ./start.sh

#. For more advanced usage, you may explicitly set the cloud provider and region when you start the demo. This may be required if you need to set the |ccloud| cluster to a specific cloud provider and region that match the cloud storage provider.

   .. code:: bash

      CLUSTER_CLOUD=aws CLUSTER_REGION=us-west-2 ./start.sh

#. As part of this script run, it creates a new |ccloud| stack of fully managed resources and generates a local configuration file with all connection information, cluster IDs, and credentials, which is useful for other demos/automation. View this local configuration file, where ``SERVICE ACCOUNT ID`` is auto-generated by the script.

   .. sourcecode:: bash

      cat stack-configs/java-service-account-<SERVICE ACCOUNT ID>.config

   Your output should resemble:

   ::

      # --------------------------------------
      # Confluent Cloud connection information
      # --------------------------------------
      # ENVIRONMENT ID: <ENVIRONMENT ID>
      # SERVICE ACCOUNT ID: <SERVICE ACCOUNT ID>
      # KAFKA CLUSTER ID: <KAFKA CLUSTER ID>
      # SCHEMA REGISTRY CLUSTER ID: <SCHEMA REGISTRY CLUSTER ID>
      # KSQLDB APP ID: <KSQLDB APP ID>
      # --------------------------------------
      ssl.endpoint.identification.algorithm=https
      security.protocol=SASL_SSL
      sasl.mechanism=PLAIN
      bootstrap.servers=<BROKER ENDPOINT>
      sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
      basic.auth.credentials.source=USER_INFO
      schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
      schema.registry.url=https://<SR ENDPOINT>
      ksql.endpoint=<KSQLDB ENDPOINT>
      ksql.basic.auth.user.info=<KSQLDB API KEY>:<KSQLDB API SECRET>


#. Log into the Confluent Cloud UI at http://confluent.cloud .


Connectors
----------

#. The demo automatically created |kconnect-long| connectors using the |ccloud| CLI command ``ccloud connector create`` that included passing in connector configuration files from the :devx-examples:`connector configuration directory|cloud-etl/connectors/`:

   - :devx-examples:`AWS Kinesis source connector configuration file|cloud-etl/connectors/kinesis.json`
   - :devx-examples:`PostgreSQL source connector configuration file|cloud-etl/connectors/rds.json`
   - :devx-examples:`GCS sink connector configuration file|cloud-etl/connectors/gcs_no_avro.json`
   - :devx-examples:`GCS sink connector with Avro configuration file|cloud-etl/connectors/gcs_avro.json`
   - :devx-examples:`S3 sink connector configuration file|cloud-etl/connectors/s3_no_avro.json`
   - :devx-examples:`S3 sink connector with Avro configuration file|cloud-etl/connectors/s3_avro.json`
   - :devx-examples:`Azure Blob sink connector configuration file|cloud-etl/connectors/az_no_avro.json`
   - :devx-examples:`Azure Blob sink connector with Avro configuration file|cloud-etl/connectors/az_avro.json`

   For example, if you configured the demo to source data from Kinesis, it ran this :devx-examples:`AWS Kinesis connector configuration file|cloud-etl/connectors/kinesis.json`.

   .. literalinclude:: ../connectors/kinesis.json

#. Let's say you ran the demo with Kinesis as the source and S3 as the sink, the pipeline would resemble:

   .. figure:: images/data-kinesis-s3.png
      :alt: image

#. Using the `Confluent Cloud CLI <https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html#step-2-install-the-ccloud-cli>`__, list all the fully-managed connectors created in this cluster.

   .. code:: bash

      ccloud connector list

   Your output should resemble:

   .. code:: bash

           ID     |        Name         | Status  |  Type  | Trace  
      +-----------+---------------------+---------+--------+-------+
        lcc-2jrx1 | demo-S3Sink-no-avro | RUNNING | sink   |        
        lcc-vnrqp | demo-KinesisSource  | RUNNING | source |        
        lcc-5qwrn | demo-S3Sink-avro    | RUNNING | sink   |       

#. Describe any running connector in more detail, in this case ``lcc-vnrqp`` which corresponds to the the AWS Kinesis connector. 

   .. code:: bash

      ccloud connector describe lcc-vnrqp

   Your output should resemble:

   .. code:: bash

      Connector Details
      +--------+--------------------+
      | ID     | lcc-vnrqp          |
      | Name   | demo-KinesisSource |
      | Status | RUNNING            |
      | Type   | source             |
      | Trace  |                    |
      +--------+--------------------+
      
      
      Task Level Details
        TaskId |  State   
      +--------+---------+
             0 | RUNNING  
      
      
      Configuration Details
              Config        |                          Value
      +---------------------+---------------------------------------------------------+
        name                | demo-KinesisSource
        kafka.api.key       | ****************
        kafka.api.secret    | ****************
        schema.registry.url | https://psrc-4yovk.us-east-2.aws.confluent.cloud
        cloud.environment   | prod
        kafka.endpoint      | SASL_SSL://pkc-4kgmg.us-west-2.aws.confluent.cloud:9092
        kafka.region        | us-west-2
        kafka.user.id       |                                                   73800
        kinesis.position    | TRIM_HORIZON
        kinesis.region      | us-west-2
        kinesis.stream      | demo-logs
        aws.secret.key.id   | ****************
        connector.class     | KinesisSource
        tasks.max           |                                                       1
        aws.access.key.id   | ****************


#. View these same connectors from the Confluent Cloud UI at https://confluent.cloud/ 

   .. figure:: images/connectors.png
      :alt: image


ksqlDB
------

#. From the `Confluent Cloud UI <https://confluent.cloud>`__, select your Kafka cluster and click the ksqlDB tab to view the `flow <https://docs.confluent.io/current/quickstart/cloud-quickstart/ksql.html#data-flow>`__ through your ksqlDB application:

   .. figure:: images/flow.png
      :alt: image

#. This flow is the result of this set of :devx-examples:`ksqlDB statements|cloud-etl/statements.sql`. It generated a ksqlDB TABLE ``COUNT_PER_SOURCE``, formatted as JSON, and its underlying Kafka topic is ``COUNT_PER_SOURCE``. It also generated a ksqlDB TABLE ``SUM_PER_SOURCE``, formatted as Avro, and its underlying Kafka topic is ``SUM_PER_SOURCE``.

   .. literalinclude:: ../statements.sql

#. Use the Confluent Cloud ksqlDB UI or its REST API to interact with the ksqlDB application:

   .. code:: bash

      curl -X POST $KSQLDB_ENDPOINT/ksql \
             -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
             -u $KSQLDB_BASIC_AUTH_USER_INFO \
             -d @<(cat <<EOF
      {
        "ksql": "SHOW QUERIES;",
        "streamsProperties": {}
      }
      EOF
      )

   Your output should resemble:

   .. code:: bash

      [
        {
          "@type": "queries",
          "statementText": "SHOW QUERIES;",
          "queries": [
            {
              "sinks": [
                "COUNT_PER_SOURCE"
              ],
              "id": "CTAS_COUNT_PER_SOURCE_210",
              "queryString": "CREATE TABLE COUNT_PER_SOURCE WITH (KAFKA_TOPIC='COUNT_PER_SOURCE', PARTITIONS=6, REPLICAS=3) AS SELECT\n  EVENTLOGS.EVENTSOURCEIP \"EVENTSOURCEIP\",\n  COUNT(*) \"COUNT\"\nFROM EVENTLOGS EVENTLOGS\nGROUP BY EVENTLOGS.EVENTSOURCEIP\nEMIT CHANGES;"
            },
            {
              "sinks": [
                "SUM_PER_SOURCE"
              ],
              "id": "CTAS_SUM_PER_SOURCE_211",
              "queryString": "CREATE TABLE SUM_PER_SOURCE WITH (KAFKA_TOPIC='SUM_PER_SOURCE', PARTITIONS=6, REPLICAS=3, VALUE_FORMAT='AVRO') AS SELECT\n  EVENTLOGS.EVENTSOURCEIP \"EVENTSOURCEIP\",\n  SUM(EVENTLOGS.EVENTDURATION) \"SUM\"\nFROM EVENTLOGS EVENTLOGS\nWHERE (EVENTLOGS.RESULT = 'Pass')\nGROUP BY EVENTLOGS.EVENTSOURCEIP\nEMIT CHANGES;"
            }
          ],
          "warnings": []
        }
      ]


#. View the Avro schema for the topic ``SUM_PER_SOURCE`` in |sr-ccloud|.

   .. code:: bash

      curl --silent -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects/SUM_PER_SOURCE-value/versions/latest | jq -r '.schema' | jq .

   Your output should resemble:

   .. code:: json

      {
        "type": "record",
        "name": "KsqlDataSourceSchema",
        "namespace": "io.confluent.ksql.avro_schemas",
        "fields": [
          {
            "name": "EVENTSOURCEIP",
            "type": [
              "null",
              "string"
            ],
            "default": null
          },
          {
            "name": "SUM",
            "type": [
              "null",
              "long"
            ],
            "default": null
          }
        ]
      }

#. View these same queries from the Confluent Cloud UI at https://confluent.cloud/ 

.. figure:: images/ksqldb_queries.png
   :alt: image


Validate
--------


#. View the data from Kinesis, |ak|, and cloud storage after running the demo, running the :devx-examples:`read-data.sh|cloud-etl/read-data.sh` script.

   .. code:: bash

      ./read-data.sh stack-configs/java-service-account-<SERVICE ACCOUNT ID>.config

   Your output should resemble:

   .. code:: shell

      Data from Kinesis stream demo-logs --limit 10:
      {"eventSourceIP":"192.168.1.1","eventAction":"Upload","result":"Pass","eventDuration":3}
      {"eventSourceIP":"192.168.1.1","eventAction":"Create","result":"Pass","eventDuration":2}
      {"eventSourceIP":"192.168.1.1","eventAction":"Delete","result":"Fail","eventDuration":5}
      {"eventSourceIP":"192.168.1.2","eventAction":"Upload","result":"Pass","eventDuration":1}
      {"eventSourceIP":"192.168.1.2","eventAction":"Create","result":"Pass","eventDuration":3}
      {"eventSourceIP":"192.168.1.1","eventAction":"Upload","result":"Pass","eventDuration":3}
      {"eventSourceIP":"192.168.1.1","eventAction":"Create","result":"Pass","eventDuration":2}
      {"eventSourceIP":"192.168.1.1","eventAction":"Delete","result":"Fail","eventDuration":5}
      {"eventSourceIP":"192.168.1.2","eventAction":"Upload","result":"Pass","eventDuration":1}
      {"eventSourceIP":"192.168.1.2","eventAction":"Create","result":"Pass","eventDuration":3}
   
      Data from Kafka topic eventlogs:
      confluent local consume eventlogs -- --cloud --config stack-configs/java-service-account-<SERVICE ACCOUNT ID>.config --from-beginning --property print.key=true --max-messages 10
      5   {"eventSourceIP":"192.168.1.5","eventAction":"Upload","result":"Pass","eventDuration":4}
      5   {"eventSourceIP":"192.168.1.5","eventAction":"Create","result":"Pass","eventDuration":1}
      5   {"eventSourceIP":"192.168.1.5","eventAction":"Delete","result":"Fail","eventDuration":1}
      5   {"eventSourceIP":"192.168.1.5","eventAction":"Upload","result":"Pass","eventDuration":4}
      5   {"eventSourceIP":"192.168.1.5","eventAction":"Create","result":"Pass","eventDuration":1}
      5   {"eventSourceIP":"192.168.1.5","eventAction":"Delete","result":"Fail","eventDuration":1}
      5   {"eventSourceIP":"192.168.1.5","eventAction":"Upload","result":"Pass","eventDuration":4}
      5   {"eventSourceIP":"192.168.1.5","eventAction":"Create","result":"Pass","eventDuration":1}
      5   {"eventSourceIP":"192.168.1.5","eventAction":"Delete","result":"Fail","eventDuration":1}
      5   {"eventSourceIP":"192.168.1.5","eventAction":"Upload","result":"Pass","eventDuration":4}
   
      Data from Kafka topic COUNT_PER_SOURCE:
      confluent local consume COUNT_PER_SOURCE -- --cloud --config stack-configs/java-service-account-<SERVICE ACCOUNT ID>.config --from-beginning --property print.key=true --max-messages 10
      192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","COUNT":1}
      192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","COUNT":2}
      192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","COUNT":3}
      192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","COUNT":4}
      192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","COUNT":5}
      192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","COUNT":6}
      192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","COUNT":7}
      192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","COUNT":8}
      192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","COUNT":9}
      192.168.1.5	{"EVENTSOURCEIP":"192.168.1.5","COUNT":10}
   
      Data from Kafka topic SUM_PER_SOURCE:
      confluent local consume SUM_PER_SOURCE -- --cloud --config stack-configs/java-service-account-<SERVICE ACCOUNT ID>.config --from-beginning --property print.key=true --value-format avro --property basic.auth.credentials.source=USER_INFO --property schema.registry.basic.auth.user.info=$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property schema.registry.url=$SCHEMA_REGISTRY_URL --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --max-messages 10
      192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"SUM":{"long":1}}
      192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"SUM":{"long":4}}
      192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"SUM":{"long":5}}
      192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"SUM":{"long":8}}
      192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"SUM":{"long":11}}
      192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"SUM":{"long":12}}
      192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"SUM":{"long":15}}
      192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"SUM":{"long":16}}
      192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"SUM":{"long":19}}
      192.168.1.2	{"EVENTSOURCEIP":{"string":"192.168.1.2"},"SUM":{"long":22}}
   
      Objects in Cloud storage gcs:
   
      gs://confluent-cloud-etl-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+1+0000000000.bin
      gs://confluent-cloud-etl-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+1+0000001000.bin
      gs://confluent-cloud-etl-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+1+0000002000.bin
      gs://confluent-cloud-etl-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+1+0000003000.bin
      gs://confluent-cloud-etl-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+1+0000004000.bin
      gs://confluent-cloud-etl-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+3+0000000000.bin
      gs://confluent-cloud-etl-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+3+0000001000.bin
      gs://confluent-cloud-etl-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+3+0000002000.bin
      gs://confluent-cloud-etl-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+3+0000003000.bin
      gs://confluent-cloud-etl-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+3+0000004000.bin
      gs://confluent-cloud-etl-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+1+0000000000.avro
      gs://confluent-cloud-etl-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+1+0000001000.avro
      gs://confluent-cloud-etl-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+1+0000002000.avro
      gs://confluent-cloud-etl-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+1+0000003000.avro
      gs://confluent-cloud-etl-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+3+0000000000.avro
      gs://confluent-cloud-etl-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+3+0000001000.avro
      gs://confluent-cloud-etl-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+3+0000002000.avro
      gs://confluent-cloud-etl-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+3+0000003000.avro


#. Add more entries in the source and see them propagate through the pipeline by viewing messages in the Confluent Cloud UI or CLI.

   If you are running Kinesis:

   .. code:: bash

      ./add_entries_kinesis.sh
      
   If you are running RDS PostgreSQL:

   .. code:: bash

      ./add_entries_rds.sh

#. View the new messages from the Confluent Cloud UI.

.. figure:: images/messages.png
   :alt: image


      
Stop
----

#. Stop the demo and clean up all the resources, delete Kafka topics, delete the fully-managed connectors, delete the data in the cloud storage:

   .. code:: bash

      ./stop.sh stack-configs/java-service-account-<SERVICE ACCOUNT ID>.config

#. Always verify that resources in |ccloud| have been destroyed.


====================
Additional Resources
====================

-  To find additional |ccloud| demos, see :ref:`Confluent Cloud Demos Overview<ccloud-demos-overview>`.
