.. _quickstart-demos-operator-replicator-gke-cc:

Bridge to |ccloud| with |crep-full|
===================================

Overview
--------

This demonstrations features a deployment of |cp| on Google Kubernetes Engine (GKE) leveraging |co-long| and |crep-full|, highlighting a data replication strategy to |ccloud|.

The major components of this demo are:

* A |ccloud| environment
* A Kubernetes cluster running on GKE.
* |co-long| which is used to manage the following |cp| components

  * A 3 node |zk| cluster
  * A 3 node node |ak| cluster
  * A single node |crep|
  * A single node |sr|
  * A single node |kconnect-long|
  * |c3|
  * One instance of ``kafka-connect-datagen`` to produce mock stock trading data

.. figure:: images/operator-demo-phase-2.png
    :alt: operator

Demo Prerequisites
-------------------
The following applications or libraries are required to be installed and available in the system path in order to properly run the demo.

+------------------+----------------+---------------------------------------------------------+
| Application      | Tested Version | Info                                                    |
+==================+================+=========================================================+
| ``kubectl``      | ``1.14.3``     | https://kubernetes.io/docs/tasks/tools/install-kubectl/ |
+------------------+----------------+---------------------------------------------------------+
| ``helm``         | ``2.14.3``     | https://helm.sh/docs/using_helm/#install-helm           |
+------------------+----------------+---------------------------------------------------------+
| ``gcloud``       | ``267.0.0``    |  https://cloud.google.com/sdk/install                   |
| ``GCP sdk core`` | ``2019.10.15`` |                                                         |
+------------------+----------------+---------------------------------------------------------+

Running the Demo
----------------

.. warning:: This demo uses the real GCP SDK to launch real resources. To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done evaluating the demonstration.  Optionally, refer to the |co| :ref:`Sizing Recommendations <co-env-sizing>` document and the :ref:`examples-operator-gke-base-variable-reference` section for more information on required resources for running |cp| on Kubernetes.

 
Setup
*****

Clone the Confluent examples repository and change directories on your terminal into the ``replicator-gke-cc`` directory.

.. sourcecode:: bash

    git clone git@github.com:confluentinc/examples.git
    cd examples/kubernetes/replicator-gke-cc

In order to properly simulate a realistic replication scenario to |ccloud|, the demo requires a GKE Node Pool sufficiently large to support 3 node |zk| and 3 node |ak| clusters.  In testing this demonstration a sufficient cluster consisted of 7 nodes of machine type ``h1-highmem-2``.  The demo contains a ``make`` function to assist you in creating a cluster in GKE assuming you have your ``glcoud`` SDK properly configured to access your account.

If you wish to override the behavior of the create cluster script, you can modify the following variables and pass them into the `make` command.  The following section shows the variables and their defaults.  The variables can be set prior to the ``make`` command, such as ``GKE_BASE_ZONE=us-central1-b make ...``.

.. sourcecode:: bash

		GKE_BASE_REGION ?= us-central1
		GKE_BASE_ZONE ?= us-central1-a
		GKE_BASE_SUBNET ?= default
		GKE_BASE_CLUSTER_VERSION ?= 1.13.7-gke.24
		GKE_BASE_MACHINE_TYPE ?= n1-highmem-2
		GKE_BASE_IMAGE_TYPE ?= COS
		GKE_BASE_DISK_TYPE ?= pd-standard
		GKE_BASE_DISK_SIZE ?= 100

To create the standard cluster you can run the following:

.. sourcecode:: bash

    make gke-create-cluster

After the cluster is created you can verify it's status with the following:

.. sourcecode:: bash

		gcloud container clusters list


