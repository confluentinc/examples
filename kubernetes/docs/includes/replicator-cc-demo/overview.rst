This demo is featured in the `Conquering Hybrid Cloud with Replicated Event-Driven Architectures blog post <https://www.confluent.io/blog/replicated-event-driven-architectures-for-hybrid-cloud-kafka/>`__ which provides more details on use cases for replicated event streaming architectures.

The major components of this demo are:

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
