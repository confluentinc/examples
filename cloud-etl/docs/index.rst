.. _cloud-etl:
  
.. toctree::
    :maxdepth: 2

Cloud ETL Demo
==============

This demo showcases a cloud ETL solution leveraging all fully-managed services on `Confluent Cloud <https://confluent.cloud>`__.
Using |ccloud| CLI, the demo creates a source connector that reads data from an AWS Kinesis stream into |ccloud|, then a |ccloud| ksqlDB application processes that data, and then a sink connector writes the output data into cloud storage in the provider of your choice (one of GCP GCS, AWS S3, or Azure Blob).

.. figure:: images/topology.png
   :alt: image

The end result is an event streaming ETL, running 100% in the cloud, spanning multiple cloud providers.
This enables you to:

*  Build business applications on a full event streaming platform
*  Span multiple cloud providers (AWS, GCP, Azure) and on-prem datacenters
*  Use Kafka to aggregate data in single source of truth
*  Harness the power of `ksqlDB <https://www.confluent.io/product/ksql/>`__ for stream processing

.. tip:: For more information about building a cloud ETL pipeline on |ccloud|, see this
         `blog post <https://www.confluent.io/blog/build-a-cloud-etl-pipeline-with-confluent-cloud/>`__.


========================
End-to-end Streaming ETL
========================

This demo showcases an entire end-to-end cloud ETL deployment, built for 100% cloud services:

-  Kinesis source connector: reads from a Kinesis stream and writes the data to a Kafka topic in |ccloud|

   - :ref:`cc_kinesis-source`

-  ksqlDB: streaming SQL engine that enables real-time data processing against Kafka

   - `Confluent Cloud ksqlDB <https://docs.confluent.io/current/quickstart/cloud-quickstart/ksql.html>`__

-  Cloud storage sink connector: writes data from Kafka topics to cloud storage, one of:

   - :ref:`cc_azure_blob_sink`
   - :ref:`cc_gcs_connect_sink`
   - :ref:`cc_s3_connect_sink`

-  |sr-ccloud|: for centralized management of schemas and checks compatibility as schemas evolve 


Data Flow
---------

The data set is a stream of log messages, which in this demo is mock data captured in :devx-examples:`eventLogs.json|cloud-etl/eventLogs.json`.

+-----------------------+-----------------------+-----------------------+
| Component             | Consumes From         | Produces To           |
+=======================+=======================+=======================+
| Kinesis source        | Kinesis stream        | Kafka topic           |
| connector             | ``demo-logs``         | ``eventLogs``         |
+-----------------------+-----------------------+-----------------------+
| ksqlDB                | ``eventLogs``         | ksqlDB streams and    |
|                       |                       | tables                |
+-----------------------+-----------------------+-----------------------+
| GCS/S3/Blob sink      | ksqlDB tables         | GCS/S3/Blob           |
| connector             | ``COUNT_PER_SOURCE``, |                       |
|                       | ``SUM_PER_SOURCE``    |                       |
+-----------------------+-----------------------+-----------------------+

=======
Caution
=======

This demo uses real cloud resources, including that of |ccloud|, AWS Kinesis, and one of the cloud storage providers.
To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done running it.

=============
Prerequisites
=============

Cloud services
--------------

-  `Confluent Cloud cluster <https://confluent.cloud>`__: for development only. Do not use a production cluster.
-  `Confluent Cloud ksqlDB <https://docs.confluent.io/current/quickstart/cloud-quickstart/ksql.html>`__ provisioned in your |ccloud|
-  AWS or GCP or Azure access

Local Tools
-----------

-  `Confluent Cloud CLI <https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html#step-2-install-the-ccloud-cli>`__ v0.239.0 or later
-  ``gsutil`` CLI, properly initialized with your credentials: (optional) if destination is GPC GCS
-  ``aws`` CLI, properly initialized with your credentials: used for AWS Kinesis and (optional) if destination is AWS S3
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

Because this demo interacts with real resources in Kinesis, a destination storage service, and |ccloud|, you must set up some initial parameters to communicate with these services.

#. By default, the demo reads the configuration parameters for your |ccloud| environment from a file at ``$HOME/.ccloud/config``. You can change this filename via the parameter ``CONFIG_FILE`` in :devx-examples:`config/demo.cfg|cloud-etl/config/demo.cfg`. Enter the configuration parameters for your |ccloud| cluster, replacing the values in ``<...>`` below particular for your |ccloud| environment:

   .. code:: shell

      cat $HOME/.ccloud/config

   Your output should resemble:

   ::

      bootstrap.servers=<BROKER ENDPOINT>
      ssl.endpoint.identification.algorithm=https
      security.protocol=SASL_SSL
      sasl.mechanism=PLAIN
      sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
      schema.registry.url=https://<SR ENDPOINT>
      schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
      basic.auth.credentials.source=USER_INFO
      ksql.endpoint=https://<ksqlDB ENDPOINT>
      ksql.basic.auth.user.info=<ksqlDB API KEY>:<ksqlDB API SECRET>

   To retrieve the values for the endpoints and credentials in the file above, find them using either the |ccloud| UI or |ccloud| CLI commands. If you have multiple |ccloud| clusters, make sure to use the one with the associated ksqlDB cluster.  The commands below demonstrate how to retrieve the values using the |ccloud| CLI.

   .. code:: shell

      # Login
      ccloud login --url https://confluent.cloud
   
      # BROKER ENDPOINT
      ccloud kafka cluster list
      ccloud kafka cluster use
      ccloud kafka cluster describe
   
      # SR ENDPOINT
      ccloud schema-registry cluster describe
   
      # ksqlDB ENDPOINT
      ccloud ksql app list
   
      # Credentials: API key and secret, one for each resource above
      ccloud api-key create

#. Clone the `examples GitHub repository <https://github.com/confluentinc/examples>`__ and check out the :litwithvars:`|release|-post` branch.

   .. codewithvars:: bash

     git clone https://github.com/confluentinc/examples
     cd examples
     git checkout |release|-post

#. Change directory to the Cloud ETL demo at ``cloud-etl``:

   .. codewithvars:: bash

     cd cloud-etl


#. Modify the demo configuration file at :devx-examples:`config/demo.cfg|cloud-etl/config/demo.cfg`. Set the proper credentials and parameters for the source, e.g. AWS Kinesis.  Also set the required parameters for the respective destination cloud storage provider:

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

#. Run the demo. It takes approximately 7 minutes to run.

   .. code:: bash

      ./start.sh

Validate
--------

#. The demo automatically created |kconnect-long| connectors using the |ccloud| CLI command ``ccloud connector create`` that included passing in a configuration file from the :devx-examples:`connector configuration directory|cloud-etl/connectors/`. For example, here is the :devx-examples:`AWS Kinesis connector configuration file|cloud-etl/connectors/kinesis.json` used in the demo.

   .. literalinclude:: ../connectors/kinesis.json

#. Using the `Confluent Cloud CLI <https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html#step-2-install-the-ccloud-cli>`__, list all the fully-managed connectors created in this cluster.

   .. code:: bash

      ccloud connector list

   Your output should resemble:

   .. code:: bash

           ID     |         Name         | Status  |  Type
      +-----------+----------------------+---------+--------+
        lcc-knjgv | demo-KinesisSource   | RUNNING | source
        lcc-nwkxv | demo-GcsSink-avro    | RUNNING | sink
        lcc-3r7w2 | demo-GcsSink-no-avro | RUNNING | sink

#. Describe any running connector in more detail, in this case ``lcc-knjgv`` which corresponds to the the AWS Kinesis connector. 

   .. code:: bash

      ccloud connector describe lcc-knjgv

   Your output should resemble:

   .. code:: bash

      Connector Details
      +--------+--------------------+
      | ID     | lcc-knjgv          |
      | Name   | demo-KinesisSource |
      | Status | RUNNING            |
      | Type   | source             |
      +--------+--------------------+
      
      
      Task Level Details
        Task_ID |  State   
      +---------+---------+
              0 | RUNNING  
      
      
      Configuration Details
           Configuration    |                          Value                           
      +---------------------+---------------------------------------------------------+
        schema.registry.url | https://psrc-lz3xz.us-central1.gcp.confluent.cloud       
        value.converter     | io.confluent.connect.replicator.util.ByteArrayConverter  
        aws.access.key.id   | ****************                                         
        kafka.region        | us-west2                                                 
        tasks.max           |                                                       1  
        aws.secret.key.id   | ****************                                         
        kafka.topic         | eventLogs                                                
        kafka.api.key       | ****************                                         
        kinesis.position    | TRIM_HORIZON                                             
        kinesis.region      | us-west-2                                                
        kinesis.stream      | demo-logs                                                
        cloud.environment   | prod                                                     
        connector.class     | KinesisSource                                            
        key.converter       | org.apache.kafka.connect.storage.StringConverter         
        name                | demo-KinesisSource                                       
        kafka.api.secret    | ****************                                         
        kafka.endpoint      | SASL_SSL://pkc-4r087.us-west2.gcp.confluent.cloud:9092   


#. From the `Confluent Cloud UI <https://confluent.cloud>`__, select your Kafka cluster and click the ksqlDB tab to view the `flow <https://docs.confluent.io/current/quickstart/cloud-quickstart/ksql.html#data-flow>`__ through your ksqlDB application:

   .. figure:: images/flow.png
      :alt: image

#. This flow is the result of this set of :devx-examples:`ksqlDB statements|cloud-etl/statements.sql`. It generated a ksqlDB TABLE ``COUNT_PER_SOURCE``, formatted as JSON, and its underlying Kafka topic is ``COUNT_PER_SOURCE``. It also generated a ksqlDB TABLE ``SUM_PER_SOURCE``, formatted as Avro, and its underlying Kafka topic is ``SUM_PER_SOURCE``.

   .. literalinclude:: ../statements.sql

#. Use the Confluent Cloud ksqlDB UI or its REST API to interact with the ksqlDB application:

   .. code:: bash

      curl -X POST $KSQL_ENDPOINT/ksql \
             -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
             -u $KSQL_BASIC_AUTH_USER_INFO \
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


#. View the data from Kinesis, |ak|, and cloud storage after running the demo, running the :devx-examples:`provided script|cloud-etl/read-data.sh`.

   .. code:: bash

      ./read-data.sh

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
   
      Data from Kafka topic eventLogs:
      confluent local consume eventLogs -- --cloud --from-beginning --property print.key=true --max-messages 10
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
      confluent local consume COUNT_PER_SOURCE -- --cloud --from-beginning --property print.key=true --max-messages 10
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
      confluent local consume SUM_PER_SOURCE -- --cloud --from-beginning --property print.key=true --value-format avro --property basic.auth.credentials.source=USER_INFO --property schema.registry.basic.auth.user.info=$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property schema.registry.url=$SCHEMA_REGISTRY_URL --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --max-messages 10
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
   
      gs://confluent-cloud-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+1+0000000000.bin
      gs://confluent-cloud-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+1+0000001000.bin
      gs://confluent-cloud-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+1+0000002000.bin
      gs://confluent-cloud-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+1+0000003000.bin
      gs://confluent-cloud-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+1+0000004000.bin
      gs://confluent-cloud-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+3+0000000000.bin
      gs://confluent-cloud-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+3+0000001000.bin
      gs://confluent-cloud-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+3+0000002000.bin
      gs://confluent-cloud-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+3+0000003000.bin
      gs://confluent-cloud-demo/topics/COUNT_PER_SOURCE/year=2020/month=02/day=26/hour=03/COUNT_PER_SOURCE+3+0000004000.bin
      gs://confluent-cloud-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+1+0000000000.avro
      gs://confluent-cloud-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+1+0000001000.avro
      gs://confluent-cloud-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+1+0000002000.avro
      gs://confluent-cloud-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+1+0000003000.avro
      gs://confluent-cloud-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+3+0000000000.avro
      gs://confluent-cloud-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+3+0000001000.avro
      gs://confluent-cloud-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+3+0000002000.avro
      gs://confluent-cloud-demo/topics/SUM_PER_SOURCE/year=2020/month=02/day=26/hour=03/SUM_PER_SOURCE+3+0000003000.avro
      
      
Stop
----

#. Stop the demo and clean up all the resources, delete Kafka topics, delete the fully-managed connectors, delete the data in the cloud storage:

   .. code:: bash

      ./stop.sh


====================
Additional Resources
====================

-  To find additional |ccloud| demos, see :ref:`Confluent Cloud Demos Overview<ccloud-demos-overview>`.
