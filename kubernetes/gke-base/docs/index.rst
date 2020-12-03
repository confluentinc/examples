.. _quickstart-demos-operator-gke:


.. |k8s-service-name-long| replace:: Google Kubernetes Engine
.. |k8s-service-name| replace:: GKE

|cp| on |k8s-service-name-long|
======================================

.. include:: ../../docs/includes/base-demo/overview.rst

Prerequisites
-------------
The following applications or libraries are required to be installed and available in the system path in order to properly run the demo.

+------------------+----------------+---------------------------------------------------------+
| Application      | Tested Version | Info                                                    |
+==================+================+=========================================================+
| ``kubectl``      | ``1.18.0``     | https://kubernetes.io/docs/tasks/tools/install-kubectl/ |
+------------------+----------------+---------------------------------------------------------+
| ``helm``         | ``3.1.2``      | https://github.com/helm/helm/releases/tag/v3.1.2        |
+------------------+----------------+---------------------------------------------------------+
| ``gcloud``       | ``286.0.0``    |  https://cloud.google.com/sdk/install                   |
| ``GCP sdk core`` | ``2020.03.24`` |                                                         |
+------------------+----------------+---------------------------------------------------------+

Running the Example
-------------------

.. warning:: This demo uses the real GCP SDK to launch real resources. To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done evaluating the demonstration.  Optionally, refer to the |co| `Sizing recommendations <https://docs.confluent.io/operator/current/co-plan.html#co-env-sizing>`__ document and the :ref:`examples-operator-gke-base-variable-reference` section for more information on required resources for running |cp| on Kubernetes.

 
.. _quickstart-demos-operator-gke-setup:

Setup
*****

Clone the `confluentinc/examples <https://github.com/confluentinc/examples>`__ GitHub repository, and change directories to the ``kubernetes/gke-base`` directory.

.. sourcecode:: bash

    git clone https://github.com/confluentinc/examples.git
    cd examples/kubernetes/gke-base

This demo requires a Kubernetes Cluster and ``kubectl`` context configured properly to manage it.

The remaining steps in the **Setup** section of the instructions help you build a Kubernetes cluster on Google Kubernetes Engine (GKE).  If you already have a cluster you wish to use for the demo, you can skip to the :ref:`examples-operator-gke-base-validate` section of these instructions.

To verify the Google Cloud Platform (GCP) Project in which a new cluster will be created, run the following and verify it is the desired `GCP Project ID <https://support.google.com/googleapi/answer/7014113?hl=en>`__:

.. include:: ../../docs/includes/gcloud-config-list.rst

.. note::

    For specific details on how the cluster will be created (size, region, zone, etc...), view the :ref:`examples-operator-gke-base-variable-reference` section of these instructions.  You may also use these variables to modify the default behavior of the demo create cluster functionality.

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

The last output message you should see is::

	✔ GKE Base Demo running

.. _examples-operator-gke-verify-confluent-platform:

Verify 
******

.. include:: ../../docs/includes/base-demo/verify-demo.rst

Highlights 
**********

.. _examples-operator-gke-base-configuration:

Service Configurations
``````````````````````

The |cp| Helm Charts deliver a reasonable base configuration for most deployments.  What is left to the user is the 'last mile' of configuration specific to your environment.  For this example we specify the non-default configuration in the :devx-examples:`values.yaml|kubernetes/gke-base/cfg/values.yaml` file.   The YAML file facilitates a declarative infrastructure approach, but can also be useful for viewing non-default configuration in a single place, bootstrapping a new environment, or sharing in general.

The following is an example section of the ``values.yaml`` file showing how |ak| server properties (``configOverrides``) can be configured using Helm Charts.  The example also shows a YAML anchor (``<<: *cpImage``) to promote reuse within the YAML file itself.  See the :devx-examples:`values.yaml|kubernetes/gke-base/cfg/values.yaml` for further details.

.. include:: ../../docs/includes/base-demo/highlight-service-configs.rst

Remaining configuration details are specified in individual ``helm`` commands. An example is included below showing the setting to actually enable zookeeper deployment with the ``--set`` argument on the ``helm upgrade`` command.  See the :devx-examples:`Makefile|kubernetes/gke-base/Makefile-impl` for the full commands.

.. sourcecode:: bash

  helm upgrade --install --namespace operator --set zookeeper.enabled=true ... 

.. _examples-operator-base-client-configurations:

.. include:: ../../docs/includes/base-demo/highlight-client-configs.rst

.. _examples-operator-gke-base-connector-deployments:

.. include:: ../../docs/includes/base-demo/highlight-connector-deployments.rst

.. _examples-operator-gke-base-tear-down:

Tear down
*********

To tear down the |cp| components inside the cluster, run the following (estimated running time, 4 minutes):

.. sourcecode:: bash

  make destroy-demo

You can verify that all resources are removed with::

  kubectl -n operator get all

If you used the example to create the Kubernetes cluster for you, destroy the cluster with (estimated running time, 3 minutes):

.. sourcecode:: bash

  make gke-destroy-cluster

Advanced Usage
**************

.. _examples-operator-gke-base-variable-reference:

Variable Reference
``````````````````

The following table documents variables that can be used to configure various behaviors.  Variables can be ``exported`` or set in each individual ``make`` command with either sample syntax below:

.. sourcecode:: bash

   VARIABLE=value make <make-target>
 
.. sourcecode:: bash

   make <make-target> VARIABLE=value

+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| Variable                 | Description                                                                                          | Default                                                                        |
+==========================+======================================================================================================+================================================================================+
| GCP_PROJECT_ID           | Maps to your GCP Project ID.                                                                         | The output of the command ``gcloud config list --format 'value(core.project)`` |
|                          | This is used by the example to build a new GKE cluster as well as configuring the kubectl context.   |                                                                                |
|                          | If you wish to use a different project id that the current active configuration in ``glcoud``        |                                                                                |
|                          | you should export this value in the current shell where you are running the example.                 |                                                                                |
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
| KUBECTL_CONTEXT          | Used to explicitly set the ``kubectl`` context within the example                                    | ``gke_$(GCP_PROJECT_ID)_$(GKE_BASE_ZONE)_$(GKE_BASE_CLUSTER_ID)``              |
+--------------------------+------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------+

