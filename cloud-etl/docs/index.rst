.. _cloud-etl:
  
.. toctree::
    :maxdepth: 2

Cloud ETL Demo
==============

This demo showcases a cloud ETL solution leveraging all fully-managed services on
`Confluent Cloud <https://confluent.cloud>`__.
A source connector reads data from an AWS Kinesis stream into Confluent
Cloud, a Confluent KSQL application processes that data, and then a sink
connector writes the output data into cloud storage in the provider of
your choice.

.. figure:: images/topology.jpg
   :alt: image


This enables you to:

*  Build business applications on a full event streaming platform
*  Span multiple cloud providers (AWS, GCP, Azure) and on-prem datacenters
*  Use Kafka to aggregate data in single source of truth
*  Harness the power of `KSQL <https://www.confluent.io/product/ksql/>`__


End-to-end Streaming ETL
========================

This demo showcases an entire end-to-end cloud ETL deployment, built for 100% cloud services:

-  Kinesis source connector: reads from a Kinesis stream and writes the data to a Kafka topic in |ccloud|

   - :ref:`cc_kinesis-source`

-  KSQL: streaming SQL engine that enables real-time data processing against Kafka

   - `Confluent Cloud KSQL <https://docs.confluent.io/current/quickstart/cloud-quickstart/ksql.html>`__

-  Cloud storage sink connector: pushes data from Kafka topics to cloud storage, one of:

   - :ref:`cc_azure_blob_sink`
   - :ref:`cc_gcs_connect_sink`
   - :ref:`cc_s3_connect_sink`

Here is the data flow:

+-----------------------+-----------------------+---------------------+
| Component             | Consumes From         | Produces To         |
+=======================+=======================+=====================+
| Kinesis source        | Kinesis stream        | Kafka topic         |
| connector             | ``demo-logs``         | ``eventLogs``       |
+-----------------------+-----------------------+---------------------+
| KSQL                  | ``eventLogs``         | KSQL streams and    |
|                       |                       | tables              |
|                       |                       | (`ksql.commands     |
|                       |                       | <ksql.commands>`__) |
+-----------------------+-----------------------+---------------------+
| GCS/S3/Blob sink      | KSQL tables           | GCS/S3/Blob         |
| connector             | ``COUNT_PER_SOURCE``, |                     |
|                       | ``SUM_PER_SOURCE``    |                     |
+-----------------------+-----------------------+---------------------+

Warning
=======

This demo uses real cloud resources, including that of |ccloud|,
Amazon Kinesis, and one of the cloud storage providers. To avoid
unexpected charges, carefully evaluate the cost of resources before
launching the demo and ensure all resources are destroyed after you are
done running it.

Prerequisites
=============

Cloud services
--------------

-  `Confluent Cloud cluster <https://confluent.cloud>`__: for development only. Do not use a production cluster.
-  `Confluent Cloud KSQL <https://docs.confluent.io/current/quickstart/cloud-quickstart/ksql.html>`__ provisioned in your |ccloud|
-  Download `Confluent Platform <https://www.confluent.io/download/>`__ |release|: for more advanced Confluent CLI functionality (optional)
-  AWS or GCP or Azure access

Local Tools
-----------

-  `Confluent Cloud CLI <https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html#step-2-install-the-ccloud-cli>`__
   v0.234.0 or later
-  ``aws`` CLI, properly initialized with your credentials: AWS Kinesis and (optional) if destination is AWS S3
-  ``gsutil`` CLI, properly initialized with your credentials: (optional) if destination is GPC GCS
-  ``az`` CLI, properly initialized with your credentials: (optional) if destination is Azure Blob storage
-  ``jq``
-  ``curl``
-  ``timeout``

Run the Demo
============

Setup
-----

#. By default, the demo reads the configuration parameters for your |ccloud| environment from a file at ``$HOME/.ccloud/config``. You can change this filename via the parameter ``CONFIG_FILE`` in :devx-examples:`config/demo.cfg|cloud-etl/config/demo.cfg`. Enter the configuration parameters for your |ccloud| cluster, replacing the values in ``<...>`` below particular for your |ccloud| environment:

   .. code:: shell

      $ cat $HOME/.ccloud/config
      bootstrap.servers=<BROKER ENDPOINT>
      ssl.endpoint.identification.algorithm=https
      security.protocol=SASL_SSL
      sasl.mechanism=PLAIN
      sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
      schema.registry.url=https://<SR ENDPOINT>
      schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
      basic.auth.credentials.source=USER_INFO
      ksql.endpoint=https://<KSQL ENDPOINT>
      ksql.basic.auth.user.info=<KSQL API KEY>:<KSQL API SECRET>

   To get the right values for the endpoints and credentials in the file above, find them either via the |ccloud| UI or |ccloud| CLI commands. If you have multiple |ccloud| clusters, make sure to use the one with the associated KSQL cluster.

   .. code:: shell

      # Login
      ccloud login --url https://confluent.cloud
   
      # BROKER ENDPOINT
      ccloud kafka cluster list
      ccloud kafka cluster use
      ccloud kafka cluster describe
   
      # SR ENDPOINT
      ccloud schema-registry cluster describe
   
      # KSQL ENDPOINT
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


#. Modify the demo configuration file at :devx-examples:`config/demo.cfg|cloud-etl/config/demo.cfg`. Set the proper credentials and parameters for the source, e.g. AWS Kinesis.  Also set the parameters for the destination cloud storage provider:

   - AWS S3: set ``DESTINATION_STORAGE='s3'``, ``S3_PROFILE``, and ``S3_BUCKET``.
   - Azure Blob: set ``DESTINATION_STORAGE='az'``, ``AZBLOB_STORAGE_ACCOUNT``, and ``AZBLOB_CONTAINER``.

#. Log into |ccloud| with the command ``ccloud login``, and use
   your |ccloud| username and password.

   .. code:: shell

      ccloud login --url https://confluent.cloud


Run
---

#. Run the demo. It takes approximately 7 minutes to run.

   .. code:: bash

      $ ./start.sh

Validate
--------

#. From the `Confluent Cloud UI <https://confluent.cloud>`__, select your Kafka cluster and click the KSQL tab to view the flow through your KSQL application:

   .. figure:: images/flow.png
      :alt: image


#. View all the data from Kinesis, Kafka, and cloud storage after
   running the demo:

   .. code:: bash

      $ ./read-data.sh

   Sample output:

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
      192.168.1.5 {"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":1}
      192.168.1.5 {"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":2}
      192.168.1.5 {"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":3}
      192.168.1.5 {"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":4}
      192.168.1.5 {"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":5}
      192.168.1.5 {"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":6}
      192.168.1.5 {"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":7}
      192.168.1.5 {"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":8}
      192.168.1.5 {"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":9}
      192.168.1.5 {"EVENTSOURCEIP":"192.168.1.5","KSQL_COL_1":10}
   
      Data from Kafka topic SUM_PER_SOURCE:
      confluent local consume SUM_PER_SOURCE -- --cloud --from-beginning --property print.key=true --value-format avro --property basic.auth.credentials.source=USER_INFO --property schema.registry.basic.auth.user.info=WZVZVUOIOYEITVDY:680fJRxdHGIkK3dVisMEM5nl6b+d74xvPgRhlUx4i/OQpT3B+Zlz2qtVEE01wKto --property schema.registry.url=https://psrc-lz3xz.us-central1.gcp.confluent.cloud --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --max-messages 10
      192.168.1.2 {"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":1}}
      192.168.1.2 {"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":4}}
      192.168.1.2 {"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":5}}
      192.168.1.2 {"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":8}}
      192.168.1.2 {"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":11}}
      192.168.1.2 {"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":12}}
      192.168.1.2 {"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":15}}
      192.168.1.2 {"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":16}}
      192.168.1.2 {"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":19}}
      192.168.1.2 {"EVENTSOURCEIP":{"string":"192.168.1.2"},"KSQL_COL_1":{"long":22}}
   
      Objects in Cloud storage s3:
   
      S3 key: topics/COUNT_PER_SOURCE/year=2020/month=02/day=12/hour=23/COUNT_PER_SOURCE+1+0000000000.bin
      S3 key: topics/COUNT_PER_SOURCE/year=2020/month=02/day=12/hour=23/COUNT_PER_SOURCE+1+0000001000.bin
      S3 key: topics/COUNT_PER_SOURCE/year=2020/month=02/day=12/hour=23/COUNT_PER_SOURCE+1+0000002000.bin
      S3 key: topics/COUNT_PER_SOURCE/year=2020/month=02/day=12/hour=23/COUNT_PER_SOURCE+1+0000003000.bin
      S3 key: topics/COUNT_PER_SOURCE/year=2020/month=02/day=12/hour=23/COUNT_PER_SOURCE+1+0000004000.bin
      S3 key: topics/COUNT_PER_SOURCE/year=2020/month=02/day=12/hour=23/COUNT_PER_SOURCE+3+0000000000.bin
      S3 key: topics/COUNT_PER_SOURCE/year=2020/month=02/day=12/hour=23/COUNT_PER_SOURCE+3+0000001000.bin
      S3 key: topics/COUNT_PER_SOURCE/year=2020/month=02/day=12/hour=23/COUNT_PER_SOURCE+3+0000002000.bin
      S3 key: topics/COUNT_PER_SOURCE/year=2020/month=02/day=12/hour=23/COUNT_PER_SOURCE+3+0000003000.bin
      S3 key: topics/COUNT_PER_SOURCE/year=2020/month=02/day=12/hour=23/COUNT_PER_SOURCE+3+0000004000.bin
      S3 key: topics/SUM_PER_SOURCE/year=2020/month=02/day=12/hour=23/SUM_PER_SOURCE+1+0000000000.avro
      S3 key: topics/SUM_PER_SOURCE/year=2020/month=02/day=12/hour=23/SUM_PER_SOURCE+1+0000001000.avro
      S3 key: topics/SUM_PER_SOURCE/year=2020/month=02/day=12/hour=23/SUM_PER_SOURCE+1+0000002000.avro
      S3 key: topics/SUM_PER_SOURCE/year=2020/month=02/day=12/hour=23/SUM_PER_SOURCE+1+0000003000.avro
      S3 key: topics/SUM_PER_SOURCE/year=2020/month=02/day=12/hour=23/SUM_PER_SOURCE+1+0000004000.avro
      S3 key: topics/SUM_PER_SOURCE/year=2020/month=02/day=12/hour=23/SUM_PER_SOURCE+3+0000000068.avro
      S3 key: topics/SUM_PER_SOURCE/year=2020/month=02/day=12/hour=23/SUM_PER_SOURCE+3+0000001068.avro
      S3 key: topics/SUM_PER_SOURCE/year=2020/month=02/day=12/hour=23/SUM_PER_SOURCE+3+0000002068.avro
      S3 key: topics/SUM_PER_SOURCE/year=2020/month=02/day=12/hour=23/SUM_PER_SOURCE+3+0000003068.avro
      S3 key: topics/SUM_PER_SOURCE/year=2020/month=02/day=12/hour=23/SUM_PER_SOURCE+3+0000004068.avro


Stop
----

#. Stop the demo and clean up all the resources, delete Kafka topics, delete the fully-managed connectors, delete the data in the cloud storage:

   .. code:: bash

      $ ./stop.sh
