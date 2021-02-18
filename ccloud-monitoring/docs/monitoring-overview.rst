.. _ccloud-monitoring-overview:

Monitor Overview and Setup
--------------------------

Using |ccloud| has the advantage of circumventing the trials and tribulations of monitoring
a Kafka cluster but you still need to monitor your client applications. Your success in Confluent
Cloud largely depends on how well your applications are performing. Monitoring your client
applications gives you insights on how to fine tune your producers and consumers, when to scale
your |ccloud| cluster, what might be going wrong and how to resolve the problem.

This module will cover how to setup a time-series database populated with data from the
|ccloud| Metrics API and client metrics from a locally running Java consumer and producer,
along with how to setup a data visualization tool. After the initial setup, you will
follow a series of use cases that create failure scenarios and how you can be alerted when they occur.

.. note::

   This example uses Prometheus as the time-series database and Grafana for visualization, but the same principles can be applied to any other technologies.


Prerequisites
~~~~~~~~~~~~~

-  Access to `|ccloud| <https://confluent.cloud/login>`__.

-  Local `install of |ccloud| CLI
   <https://docs.confluent.io/ccloud-cli/current/install.html>`__ (v1.21.0 or later)

-  .. include:: ../../ccloud/docs/includes/prereq_timeout.rst

-  `mvn <https://maven.apache.org/install.html>`__ installed on your host

-  `jq <https://github.com/stedolan/jq/wiki/Installation>`__ installed on your host

-  `Docker <https://docs.docker.com/get-docker/>`__ installed on your host

Cost to Run Tutorial
~~~~~~~~~~~~~~~~~~~~

Caution
^^^^^^^

.. include:: ../../ccloud/docs/includes/ccloud-examples-caution.rst

|ccloud| Promo Code
^^^^^^^^^^^^^^^^^^^

.. include:: ../../ccloud/docs/includes/ccloud-examples-promo-code.rst

|ccloud| Cluster Setup
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Log in to the |ccloud| CLI:

   .. code-block:: bash

      ccloud login --save

   The ``--save`` flag will save your |ccloud| login credentials to the
   ``~/.netrc`` file.


#. Clone the `confluentinc/examples <https://github.com/confluentinc/examples>`__ GitHub repository.

   .. code-block:: bash

       git clone https://github.com/confluentinc/examples.git

#. Navigate to the ``examples/ccloud-monitoring/`` directory and switch to
   the |cp| release branch:

   .. codewithvars:: bash

       cd examples/ccloud-monitoring/
       git checkout |release_post_branch|

#. If you already have a |ccloud| cluster, you may proceed to the `Monitoring Container Setup`_ section.
   Alternatively, you can setup a |ccloud| cluster along with everything described in the `Monitoring Container Setup`_ section by running
   :devx-examples:`start.sh script|ccloud-monitoring/start.sh`:

   .. code-block:: bash

         ./start.sh

#. It will take up to 3 minutes for data to become visible in Grafana.
   Open `Grafana <localhost:3000>`__ and use the username ``admin`` and password ``password`` to login.
   Now you are ready to proceed to Producer, Consumer, or General use cases to see what different failure scenarios look like.


Monitoring Container Setup
~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Create the ``localbuild/client:latest`` docker image with the following command:

   .. code-block:: bash

      docker build -t localbuild/client:latest .

   This image caches Kafka client dependencies so that they won't need to be pulled each time you start a client container.

#. Create a service account for the clients:

   .. code-block:: bash

      TODO finish steps

#. Create a ``client.config``, filling in your api key and secret values:

   .. code-block:: bash

      TODO finish steps

#. Configure the necessary ACLs to allow the clients to read, write, and create |ak| topics in |ccloud|. In this case, the service account ID is `104349`, but substitute your service account ID.

   .. code-block:: bash

      ccloud kafka acl create --allow --service-account 104349 --operation CREATE --topic demo-topic-1
      ccloud kafka acl create --allow --service-account 104349 --operation WRITE --topic demo-topic-1
      ccloud kafka acl create --allow --service-account 104349 --operation READ --topic demo-topic-1
      ccloud kafka acl create --allow --service-account 104349 --operation READ  --consumer-group demo-cloud-monitoring-1

#. Prior to starting any docker containers, create an api-key for the ``cloud`` resource with the command below. The
   `ccloud-exporter <https://github.com/Dabz/ccloudexporter/blob/master/README.md>`_ uses the
   key and secret to authenticate to |ccloud|. ``ccloud-exporter`` queries the
   `Confluent Metrics API <https://docs.confluent.io/cloud/current/monitoring/metrics-api.html>`_
   for metrics about your |ccloud| deployment and displays them in a Prometheus scrapable
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

#. Create the following environment variables, substituting in your |ccloud| API key, secret, and cluster id:

   .. code-block:: text

      export CCLOUD_API_KEY=LUFEIWBMYXD2AMN5
      export CCLOUD_API_SECRET=yad2iQkA9zxGvGYU1dmk+wiFJUNktQ3BtcRV9MrspaYhS9Z8g9ulZ7yhXtkRNNLd"
      export CCLOUD_CLUSTER=lkc-x6m01

   These environment variables will be used by the ``ccloud-exporter`` container.


#. Setup the configuration file for the ``kafka-lag-exporter``. This Prometheus exporter collects information about consumer groups.
   Modify the ``monitoring_configs/kafka-lag-exporter/application.conf`` file to point to your cluster.
   Substitute your cluster's ``name``, ``bootstrap-brokers``, and ``sasl.jaas.config`` (can be found in ``client.config`` created earlier).

   .. literalinclude:: ../monitoring_configs/kafka-lag-exporter/application.conf

#. Start up Prometheus, Grafana, a ccloud-exporter, a node-exporter, and a few Kafka clients in Docker:

   .. code-block:: bash

      docker-compose up -d

   Your output will resemble:

   .. code-block:: text

      Creating network "beginner-cloud_default" with the default driver
      Creating prometheus         ... done
      Creating grafana            ... done
      Creating kafka-lag-exporter ... done
      Creating ccloud-exporter    ... done
      Creating node-exporter      ... done
      Creating producer           ... done
      Creating consumer-1         ... done
      Creating consumer-2         ... done

#. Navigate to the Prometheus Targets page at `localhost:9090/targets <localhost:9090/targets>`__.

   |Prometheus Targets Unknown|

   This page will show you if Prometheus is scraping the targets you have created. It should look like below after a 2 minutes if everything is working.

   |Prometheus Targets Up|

#. It will take up to 3 minutes for data to become visible in Grafana.
   Open `Grafana <localhost:3000>`__ and use the username ``admin`` and password ``password`` to login.
   Now you are ready to proceed to Producer, Consumer, or General use cases to see what different failure scenarios look like.


.. |Prometheus Targets Unknown|
   image:: images/prometheus-targets-unknown.png
   :alt: Prometheus Targets Unknown

.. |Prometheus Targets Up|
   image:: images/prometheus-targets-up.png
   :alt: Prometheus Targets Up
