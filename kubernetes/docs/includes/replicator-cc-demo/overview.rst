This example features a deployment of `Confluent Platform <https://www.confluent.io/product/confluent-platform/>`__ on |k8s-service-docs-link| leveraging `Confluent Operator <https://docs.confluent.io/operator/current/overview.html>`__ and `Confluent Replicator <https://docs.confluent.io/kafka-connect-replicator/current/index.html>`__, highlighting a data replication strategy to `Confluent Cloud <https://www.confluent.io/confluent-cloud/>`__.  Upon running this example, you will have a |k8s-service-name| based |cp| deployment with simulated data replicating to your |ccloud| cluster.  We will verify the replication by running client applications against the |ccloud| cluster to view the simulated data originating in the source |k8s-service-name| cluster.

If you'd like a primer on running |co-long| in |k8s-service-name| with lower resource requirements, see the |operator-base-demo-link|.  

This example is featured in the `Conquering Hybrid Cloud with Replicated Event-Driven Architectures blog post <https://www.confluent.io/blog/replicated-event-driven-architectures-for-hybrid-cloud-kafka/>`__ which provides more details on use cases for replicated event streaming architectures.

.. note:: See the :ref:`streaming-ops` project for an example of using Kubernetes in a production-like environment targeting |ccloud|.

The major components of this example are:

* A |ccloud| Environment and |ak| Cluster
* A Kubernetes cluster running on |k8s-service-name|.
* |co-long| which is used to manage the following |cp| components

  * A 3 node |zk| cluster
  * A 3 node |ak| cluster
  * A single node |crep|
  * A single node |sr|
  * A single node |kconnect-long|
  * |c3|
  * One instance of `kafka-connect-datagen <https://github.com/confluentinc/kafka-connect-datagen>`__ to produce mock stock trading data
