.. _quickstart-demos-operator-gke

|cp| on Google Kubernetes Engine
======================================

Overview
--------

Demonstrates a deployment of |cp| on Google Kubernetes Engine (GKE) leveraging |co-long| with random data generation
provided via the `Kafka Connect Datagen <https://www.confluent.io/hub/confluentinc/kafka-connect-datagen>`__.

The major components of this demo are:

* A Kubernetes cluster running on GKE.
* |co-long| which is used to manage the following |cp| components

  * A single node |zk|
  * A single node |ak|
  * A single node |sr|
  * |c3|
  * A single node |kconnect-long|
  * One instance of `kafka-connect-datagen` to produce randomly generated data

Demo Preqrequisites
-------------------
The following applications or libraries are required to be installed and available in the system path in order to properly run the demo.

+------------------+----------------+---------------------------------------------------------+
| Application      | Tested Version | Info                                                    |
+==================+================+=========================================================+
| ``curl``         | ``7.54.0``     | https://curl.haxx.se/                                   |
+------------------+----------------+---------------------------------------------------------+
| ``kubectl``      | ``1.14.3``     | https://kubernetes.io/docs/tasks/tools/install-kubectl/ |
+------------------+----------------+---------------------------------------------------------+
| ``helm``         | ``2.14.3``     | https://helm.sh/docs/using_helm/#install-helm           |
+------------------+----------------+---------------------------------------------------------+
| ``jq``           | ``1.6``        | https://stedolan.github.io/jq/                          |
+------------------+----------------+---------------------------------------------------------+
| ``gcloud``       | ``259.0.0``    |  https://cloud.google.com/sdk/install                   |
| ``GCP sdk core`` | ``2019.08.23`` |                                                         |
+------------------+----------------+---------------------------------------------------------+

Running the Demo
----------------

.. warning:: This example uses a real provider to launch real resources. To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done evaluating the demonstration.  Optionally, refer to the |co| :ref:`Sizing Recommendations <co-env-sizing>` document and the :ref:`examples-operator-gke-base-variable-reference` section for more information on required resources for running |cp| on Kubernetes.
 
Setup
*****

This demo requires a Kubenertes Cluster and ``kubectl`` context configured properly to manage it.

The remaining steps in the **Setup** section of the instructions help you build a Kubernetes cluster on Google Kubernetes Engine (GKE).  If you already have a cluster you wish to use for the demo, you can skip to the :ref:`examples-operator-gke-base-validate` section of these instructions.

To verify the Goolge Cloud Platform (GCP) Project in which a new cluster will be created, run the following:

.. sourcecode:: bash

    gcloud config list --format 'value(core.project)'

.. note::
    For specific details on how the cluster will be created (size, region, zone, etc...), view the :ref:`examples-operator-gke-base-variable-reference` section of these instrucitons.  You may also use these variables to modify the default behavior of the demo create cluster functionality.

To create the cluster, run the following (estimated running time, 4 minutes):

.. sourcecode:: bash

    make gke-create-cluster

Verify that ``gcloud`` has created the cluster properly::

    ...
    Created [https://container.googleapis.com/v1/projects/<project-id>/zones/us-central1-a/clusters/cp-examples-operator-<username>].
    To inspect the contents of your cluster, go to: <link> 
    kubeconfig entry generated for cp-examples-operator-<username>.
    NAME                            LOCATION  MASTER_VERSION  MASTER_IP     MACHINE_TYPE  NODE_VERSION   NUM_NODES  STATUS
    cp-examples-operator-<username> <zone>    1.12.8-gke.10   <ip-address>  n1-highmem-2  1.12.8-gke.10  3          RUNNING
    ✔  ++++++++++ GKE Cluster Created

.. _examples-operator-gke-base-validate:

Validate
********

The demo uses ``kubectl`` to control the cluster.  To verify that your local ``kubectl`` configured as intended, run:

.. sourcecode:: bash

    kubectl config current-context

The context should contain the proper region and cluster name.  If you used the demo ``gke-create-cluster`` function to create your cluster, the context name should have the format: ``gke_<google-project-id>_<region>_<cp-examples-operator>-<username>``

.. _examples-operator-gke-base-run:

Run
***

To deploy |cp| run (estimated running time, 7 minutes):

.. sourcecode:: bash

    make demo

.. _examples-operator-gke-verify-confluent-platform:

Verify 
******

You can view the deploye components with:

.. sourcecode: bash

    kubectl -n operator get all

Using the default demo variable values, ``kubectl`` should report something like the following::

	NAME                                        READY   STATUS      RESTARTS   AGE
	pod/cc-manager-566965d74f-fgqfb             1/1     Running     2          22m
	pod/cc-operator-76c54d65cd-cjzk2            1/1     Running     0          22m
	pod/clicks-datagen-connector-deploy-c2v69   0/1     Completed   0          16m
	pod/connectors-0                            1/1     Running     0          18m
	pod/controlcenter-0                         1/1     Running     0          16m
	pod/kafka-0                                 1/1     Running     0          20m
	pod/schemaregistry-0                        1/1     Running     0          19m
	pod/zookeeper-0                             1/1     Running     0          21m

	NAME                                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                                        AGE
	service/connectors                  ClusterIP   None         <none>        8083/TCP,7203/TCP,7777/TCP                     18m
	service/connectors-0-internal       ClusterIP   10.0.8.181   <none>        8083/TCP,7203/TCP,7777/TCP                     18m
	service/controlcenter               ClusterIP   None         <none>        9021/TCP,7203/TCP,7777/TCP                     16m
	service/controlcenter-0-internal    ClusterIP   10.0.8.123   <none>        9021/TCP,7203/TCP,7777/TCP                     16m
	service/kafka                       ClusterIP   None         <none>        9071/TCP,9072/TCP,9092/TCP,7203/TCP,7777/TCP   20m
	service/kafka-0-internal            ClusterIP   10.0.2.79    <none>        9071/TCP,9072/TCP,9092/TCP,7203/TCP,7777/TCP   20m
	service/schemaregistry              ClusterIP   None         <none>        8081/TCP,7203/TCP,7777/TCP                     19m
	service/schemaregistry-0-internal   ClusterIP   10.0.3.41    <none>        8081/TCP,7203/TCP,7777/TCP                     19m
	service/zookeeper                   ClusterIP   None         <none>        3888/TCP,2888/TCP,2181/TCP,7203/TCP,7777/TCP   21m
	service/zookeeper-0-internal        ClusterIP   10.0.6.153   <none>        3888/TCP,2888/TCP,2181/TCP,7203/TCP,7777/TCP   21m

	NAME                          DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
	deployment.apps/cc-manager    1         1         1            1           22m
	deployment.apps/cc-operator   1         1         1            1           22m

	NAME                                     DESIRED   CURRENT   READY   AGE
	replicaset.apps/cc-manager-566965d74f    1         1         1       22m
	replicaset.apps/cc-operator-76c54d65cd   1         1         1       22m

	NAME                              DESIRED   CURRENT   AGE
	statefulset.apps/connectors       1         1         18m
	statefulset.apps/controlcenter    1         1         16m
	statefulset.apps/kafka            1         1         20m
	statefulset.apps/schemaregistry   1         1         19m
	statefulset.apps/zookeeper        1         1         21m

	NAME                                        COMPLETIONS   DURATION   AGE
	job.batch/clicks-datagen-connector-deploy   1/1           4s         16m

	NAME                                       AGE
	kafkacluster.cluster.confluent.com/kafka   20m

	NAME                                               AGE
	zookeepercluster.cluster.confluent.com/zookeeper   22m
 

View Cluster with Confluent Control Center
``````````````````````````````````````````

The Confluent Platform assets are now running inside the Kubernetes cluster

View Cluster on the command line
````````````````````````````````

.. _examples-oeprator-gke-base-tear-down:

Tear down
*********

Be sure to destroy the cluster after you've completed running the demo (estimated running time, 4 minutes):

.. sourcecode:: bash

  make destroy-demo

If you used the demo to create the Kubernetes cluster for you, destroy the cluster with (estimated running time, 3 minutes):

.. sourcecode:: bash

  make gke-destroy-cluster

.. _examples-operator-gke-base-variable-reference:

Variable Reference
------------------

The following table documents variables that can be used to configure various demo behaviors.  Variables can be ``exported`` or set in each indvidual make command with either sample syntax below:

.. sourcecode:: bash

   VARIABLE=value make <make-target>
 
.. sourcecode:: bash

   make <make-target> VARIABLE=value

+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| Variable                 | Description                                                                                          | Default                                                                        |
+==========================+======================================================================================================+================================================================================+
| GCP_PROJECT_ID           | Maps to your GCP Project ID.                                                                         | The output of the command ``gcloud config list --format 'value(core.project)`` |
|                          | This is used by the demo to build a new GKE cluster as well as configuring the kubectl context.      |                                                                                |
|                          | If you wish to use a different project id that the current active configuration in ``glcoud``        |                                                                                |
|                          | you should export this value in the current shell where you are running the demo.                    |                                                                                |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| GKE_BASE_CLUSTER_ID      | Identifies the GKE Cluster.  Substitutes in the current user to help with project uniqueness on GCP. | ``cp-examples-operator-$USER``                                                 |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| GKE_BASE_REGION          | Used in the ``--subnetwork`` flag to define the networking region                                    | ``us-central1``                                                                |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| GKE_BASE_ZONE            | Maps to the ``--zone`` flag                                                                          | ``us-central1-a``                                                              |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| GKE_BASE_SUBNET          | Used in the ``--subnetwork`` flag to define the subnet                                               | ``default``                                                                    |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| GKE_BASE_CLUSTER_VERSION | Maps to the ``--cluster-version`` flag                                                               | ``1.12.8-gke.10``                                                              |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| GKE_BASE_MACHINE_TYPE    | Maps to the ``--machine-type`` flag                                                                  | ``n1-highmem-2``                                                               |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| GKE_BASE_IMAGE_TYPE      | Maps to the ``--image-type`` flag.  Verify CPU Platform minimums if changing                         | ``COS``                                                                        |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| GKE_BASE_DISK_TYPE       | Maps to the ``--disk-type`` flag                                                                     | ``pd-standard``                                                                |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| GKE_BASE_DISK_SIZE       | Maps to the ``--disksize`` flag                                                                      | ``100``                                                                        |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| GKE_BASE_NUM_NODES       | Maps to the ``--num-nodes`` flag                                                                     | ``3``                                                                          |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| KUBECTL_CONTEXT          | Used to explicitly set the ``kubectl`` context within the demo                                       | ``gke_$(GCP_PROJECT_ID)_$(GKE_BASE_ZONE)_$(GKE_BASE_CLUSTER_ID)``              |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+

