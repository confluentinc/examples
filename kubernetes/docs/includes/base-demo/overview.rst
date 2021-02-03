Overview
--------

This demo shows a deployment of |cp| on |k8s-service-name-long| (|k8s-service-name|) leveraging |co-long| with mock data generation provided via the `Kafka Connect Datagen <https://www.confluent.io/hub/confluentinc/kafka-connect-datagen>`__.

.. note:: See the :ref:`streaming-ops` project for an example of using Kubernetes in a production-like environment targeting |ccloud|.

The major components of this demo are:

* A Kubernetes cluster running on |k8s-service-name|.
* |co-long| which is used to manage the following |cp| components

  * A single node |zk|
  * A single node |ak|
  * A single node |sr|
  * |c3|
  * A single node |kconnect-long|
  * One instance of ``kafka-connect-datagen`` to produce mock data

.. figure:: ../../docs/images/operator.png
    :alt: operator
