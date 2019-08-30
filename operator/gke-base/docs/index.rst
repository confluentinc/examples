.. _quickstart-demos-operator-gke

|cp| on Google Kubernetes Engine
======================================

========
Overview
========

Demonstrates a deployment of |cp| on Google Kubernetes Engine leveraging |co-long| with random data generation
provided via the `Kafka Connect Datagen <https://www.confluent.io/hub/confluentinc/kafka-connect-datagen>`__.

The major components of this demo are:

* A Kubernetes cluster running on GKE which the demo can create or the user can provide
* |co-long|, which is used to deploy and manage the following |cp| components

  * A three node |ak| & |zk| cluster
  * A two node |sr| deployment
  * A three node |kconnect-long| cluster
  * One instance of `kafka-connect-datagen` to produce randomly generated data

==============
Preqrequisites
==============

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

==========================================
Kubernetes Cluster Setup And Configuration
==========================================

This demo requires a Kubenertes Cluster and your ``kubectl`` context configured to manage it.
The demo ``Makefile`` contains a target to create a cluster for you given your ``gcloud`` SDK client 
is configured to control your ``GKE`` account.

If you already have a cluster you will be using for the demo, ensure ``kubectl`` is configured with that
cluster's context and skip to :ref:`running-the-demo`.

The following table documents the variables that can be used to configure the GKE cluster creation.
The cluster is created using the ``gcloud container clusters create`` command.  Most of the variables
map to a flag for ``gcloud`` command.

+--------------------------+------------------------------------------------------------------------------+--------------------------+
| Variable                 | Description                                                                  | Default                  |
+==========================+==============================================================================+==========================+
| GCP_PROJECT_ID           | REQUIRED: Maps to your GCP Project ID                                        |                          |
+--------------------------+------------------------------------------------------------------------------+--------------------------+
| GKE_BASE_CLUSTER_ID      | Identifies the GKE Cluster                                                   | ``cp-examples-operator`` |
+--------------------------+------------------------------------------------------------------------------+--------------------------+
| GKE_BASE_REGION          | Used in the ``--subnetwork`` flag to define the networking region            | ``us-central1``          |
+--------------------------+------------------------------------------------------------------------------+--------------------------+
| GKE_BASE_ZONE            | Maps to the ``--zone`` flag                                                  | ``us-central1-a``        |
+--------------------------+------------------------------------------------------------------------------+--------------------------+
| GKE_BASE_SUBNET          | Used in the ``--subnetwork`` flag to define the subnet                       | ``default``              |
+--------------------------+------------------------------------------------------------------------------+--------------------------+
| GKE_BASE_CLUSTER_VERSION | Maps to the ``--cluster-version`` flag                                       | ``1.12.8-gke.10``        |
+--------------------------+------------------------------------------------------------------------------+--------------------------+
| GKE_BASE_MACHINE_TYPE    | Maps to the ``--machine-type`` flag                                          | ``n1-highmem-2``         |
+--------------------------+------------------------------------------------------------------------------+--------------------------+
| GKE_BASE_IMAGE_TYPE      | Maps to the ``--image-type`` flag.  Verify CPU Platform minimums if changing | ``COS``                  |
+--------------------------+------------------------------------------------------------------------------+--------------------------+
| GKE_BASE_DISK_TYPE       | Maps to the ``--disk-type`` flag                                             | ``pd-standard``          |
+--------------------------+------------------------------------------------------------------------------+--------------------------+
| GKE_BASE_DISK_SIZE       | Maps to the ``--disksize`` flag                                              | ``100``                  |
+--------------------------+------------------------------------------------------------------------------+--------------------------+
| GKE_BASE_NUM_NODES       | Maps to the ``--num-nodes`` flag                                             | ``10``                   |
+--------------------------+------------------------------------------------------------------------------+--------------------------+

.. warning:: This example uses a real provider to launch real resources. To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done evaluating the demonstration. 

Before creating the cluster be sure to refer to the |co| :ref:`Sizing Recommendations <co-env-sizing>`.

To create a cluster with the default settings within your GCP Project ID (this command will take a few minutes to complete):

  .. sourcecode:: bash

    $ GCP_PROJECT_ID=<your-project-id> make gke-create-cluster

Alternatively, you can ``export`` the project id to make futher demo commands easier.  The following ``make`` commands do not show the explicit setting of the ``GCP_PROJECT_ID`` value.

  .. sourcecode:: bash

    $ export GCP_PROJECT_ID=<your-project-id>

After successful completion of the above command your ``kubectl`` context will have been configured to the new cluster.  The result of this command should contain your ``GCP_PROJECT_ID`` as well as the value of ``GKE_BASE_CLUSTER_ID``

  .. sourcecode:: bash

    $ kubectl config current-context 

.. _quickstart-demos-operator-gke-running
================
Running the Demo
================

  .. sourcecode:: bash

    $ make demo

