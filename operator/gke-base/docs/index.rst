.. _quickstart-demos-operator-gke

|cp| on Google Kubernetes Engine
======================================

Overview
--------

Demonstrates a deployment of |cp| on Google Kubernetes Engine leveraging |co-long| with random data generation
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

Setup
*****

This demo requires a Kubenertes Cluster and ``kubectl`` context configured properly to manage it.

The remaining steps in the Setup section of the instructions help you build a Kubernetes cluster on Google Kubernetes Engine.
If you already have a cluster you wish to use for the demo, you can skip to :ref:`Validate` section.

To verify the GCP Project in which a new cluster will be created, run the following:

.. sourcecode:: bash

    gcloud config list --format 'value(core.project)'

.. note::
    For specific details on how the cluster will be created (size, region, zone, etc...), view the :ref:`Variable Reference` section of these instrucitons.

To create the cluster, run the following (estimated execution time, 4 minutes):

.. sourcecode:: bash

    make gke-create-cluster

Verify that ``gcloud`` has created the cluster properly:

.. sourcecode:: bash

    ...
    Created [https://container.googleapis.com/v1/projects/<project-id>/zones/us-central1-a/clusters/cp-examples-operator-<username>].
    To inspect the contents of your cluster, go to: <link> 
    kubeconfig entry generated for cp-examples-operator-<username>.
    NAME                            LOCATION  MASTER_VERSION  MASTER_IP     MACHINE_TYPE  NODE_VERSION   NUM_NODES  STATUS
    cp-examples-operator-<username> <zone>    1.12.8-gke.10   <ip-address>  n1-highmem-2  1.12.8-gke.10  3          RUNNING
    ✔  ++++++++++ GKE Cluster Created


Validate
********

The demo uses ``kubectl`` to control the cluster.  To verify that your local ``kubectl`` configured as intended, run:

.. sourcecode:: bash
    kubectl config current-context

The context should contain the proper region and cluster name.

Run
***

To deploy |cp| run (estimated execution time, 11 minutes):

.. sourcecode:: bash
    make demo

Verify Confluent Platform
*************************

Tear down
*********

.. warning:: This example uses a real provider to launch real resources. To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done evaluating the demonstration. 

Before creating the cluster be sure to refer to the |co| :ref:`Sizing Recommendations <co-env-sizing>`.

To create a cluster with the default settings within your GCP Project ID (this command will take a few minutes to complete):

.. sourcecode:: bash

    make gke-create-cluster

After successful completion of the above command your ``kubectl`` context will have been configured to the new cluster.  The result of this command should contain your ``GCP_PROJECT_ID`` as well as the value of ``GKE_BASE_CLUSTER_ID``

.. sourcecode:: bash

    kubectl config current-context 

.. _gke_base_running_the_demo:

Verify

.. sourcecode:: bash

    make demo

Variable Reference
------------------

The following table documents variables that can be used to configure various demo behaviors.

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

