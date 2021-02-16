.. _ccloud-cli-tutorial-monitoring-overview:

Monitor producers and consumers
-------------------------------

Using Confluent Cloud has the advantage of circumventing the trials and tribulations of monitoring
a Kafka cluster but you still need to monitor your client applications. Your success in Confluent
Cloud largely depends on how well your applications are performing. Monitoring your client
applications will give you insights on how to fine tune your producers and consumers, when to scale
your Confluent Cloud cluster, what might be going wrong and how to resolve the problem.

This module will cover how to setup a time-series database (Prometheus) populated with data from the
Confluent Cloud Metrics API and client metrics from a locally running Java consumer and producer,
along with how to setup a data visualization tool (Grafana). After the initial setup, we will cover
a set of use cases.

Monitoring Container Setup
~~~~~~~~~~~~~~~~~~~~~~~~~~

#. First we will create a base client container and set all the necessary acls to allow our clients to read, write, and create streams.
   Create the ``localbuild/client:latest`` docker image with the following command:

   .. code-block:: bash

      docker build -t localbuild/client:latest .

   This image caches Kafka client dependencies, so that they won't need to be pulled each time we start a client container.

#. Run the following commands to create ACLs for the service account:

   .. code-block:: bash

      ccloud kafka acl create --allow --service-account 104349 --operation CREATE --topic demo-topic-4
      ccloud kafka acl create --allow --service-account 104349 --operation WRITE --topic demo-topic-4
      ccloud kafka acl create --allow --service-account 104349 --operation READ --topic demo-topic-4
      ccloud kafka acl create --allow --service-account 104349 --operation READ  --consumer-group demo-consumer-1

#. Prior to starting any docker containers, create an api-key for the ``cloud`` resource with the command below. The
   `ccloud-exporter <https://github.com/Dabz/ccloudexporter/blob/master/README.md>`_ will use the
   key and secret to authenticate to |ccloud|. ``ccloud-exporter`` queries the
   `Confluent Metrics API <https://docs.confluent.io/cloud/current/monitoring/metrics-api.html>`_
   for metrics about your Confluent Cloud deployment and displays them in a Prometheus scrapable
   webpage.

   .. code-block:: bash

      ccloud api-key create --resource cloud --description "ccloud-exporter" -o json

   Verify your output resembles:

   .. code-block:: text

      {
        "key": "LUFEIWBMYXD2AMN5",
        "secret": "yad2iQkA9zxGvGYU1dmk+wiFJUNktQ3BtcRV9MrspaYhS9Z8g9ulZ7yhXtkRNNLd"
      }

   The value of the API key, in this case ``LUFEIWBMYXD2AMN5``, and API secret, in this case
   ``yad2iQkA9zxGvGYU1dmk+wiFJUNktQ3BtcRV9MrspaYhS9Z8g9ulZ7yhXtkRNNLd``, may differ in your output.

#. Create a ``.env`` file to mimic the following:

   .. code-block:: text

      CCLOUD_API_KEY=LUFEIWBMYXD2AMN5
      CCLOUD_API_SECRET=yad2iQkA9zxGvGYU1dmk+wiFJUNktQ3BtcRV9MrspaYhS9Z8g9ulZ7yhXtkRNNLd"
      CCLOUD_CLUSTER=lkc-x6m01

   This ``.env`` file will be used by the ``ccloud-exporter`` container.


#. Next we will setup the configuration file for the ``kafka-lag-exporter``. This Prometheus exporter collects information about consumer groups.
   Modify the ``monitoring_configs/kafka-lag-exporter/application.conf`` file to point to your cluster.
   You will need to sub in information about your cluster's ``name``, ``bootstrap-brokers``, and ``sasl.jaas.config`` (can be found in ``/tmp/client.config``).

   .. literalinclude:: ../../beginner-cloud/monitoring_configs/kafka-lag-exporter/application.conf


#. Start up Prometheus, Grafana, a ccloud-exporter, a node-exporter, and a few Kafka clients by running:

   .. code-block:: bash

      docker-compose up -d


Troubleshooting
~~~~~~~~~~~~~~~

#. Data isn't showing up in Prometheus or Grafana.

   Navigate to the Prometheus Targets page at `localhost:9090/targets <localhost:9090/targets>`__.

   |Prometheus Targets Unknown|

   This page will show you if Prometheus is scraping the targets you have created. It should look like below if everything is working.

   |Prometheus Targets Up|


.. |Prometheus Targets Unknown|
   image:: ../images/prometheus-targets-unknown.png
   :alt: Prometheus Targets Unknown

.. |Prometheus Targets Up|
   image:: ../images/prometheus-targets-up.png
   :alt: Prometheus Targets Up