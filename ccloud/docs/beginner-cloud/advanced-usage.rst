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


Additional Resources
--------------------

-  See `Developing Client Applications on Confluent Cloud <https://docs.confluent.io/cloud/best-practices/index.html>`__ for a guide to configuring, monitoring, and
   optimizing your |ak| client applications when using |ccloud|.

-  See other :ref:`ccloud-demos-overview`.
