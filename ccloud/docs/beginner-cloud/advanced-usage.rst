.. _ccloud-cli-tutorial-advanced-usage:

Advanced usage
--------------

The example script provides variables that allow you to alter the default |ak|
cluster name, cloud provider, and region. For example:

.. code-block:: bash

   CLUSTER_NAME=my-demo-cluster CLUSTER_CLOUD=aws CLUSTER_REGION=us-west-2 ./start.sh

Here are the variables and their default values:

.. list-table::
   :widths: 50 50
   :header-rows: 1

   * - Variable
     - Default
   * - ``CLUSTER_NAME``
     - demo-kafka-cluster
   * - ``CLUSTER_CLOUD``
     - aws
   * - ``CLUSTER_REGION``
     - us-west-2


.. |Prometheus Targets Unknown|
image:: images/prometheus-targets-unknown.png
   :alt: Prometheus Targets Unknown

.. |Prometheus Targets Up|
image:: images/prometheus-targets-up.png
   :alt: Prometheus Targets Up

.. |Confluent Cloud Dashboard|
image:: images/confluent-cloud-dashboard.png
   :alt: Confluent Cloud Dashboard


.. |Confluent Cloud Panel|
image:: images/cloud-panel.png
   :alt: Confluent Cloud Panel

.. |Producer Connectivity Loss|
image:: images/producer-connectivity-loss.png
   :alt: Producer Connectivity Loss

Additional Resources
--------------------

-  See `Developing Client Applications on Confluent Cloud <https://docs.confluent.io/cloud/best-practices/index.html>`__ for a guide to configuring, monitoring, and
   optimizing your |ak| client applications when using |ccloud|.

-  See other :ref:`ccloud-demos-overview`.
