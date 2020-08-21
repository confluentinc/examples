.. _quickstart-demos-operator-replicator-gke-cc:

.. |k8s-service-name-long| replace:: Google Kubernetes Engine
.. |k8s-service-name| replace:: GKE
.. |operator-demo-prefix| replace:: gke
.. |kubectl-context-pattern| replace:: gke_project-name_us-central1-a_cp-examples-operator-jdoe
.. |k8s-service-docs-link| replace:: `Google Kubernetes Engine (GKE) <https://cloud.google.com/kubernetes-engine/>`__
.. |operator-base-demo-link| replace:: `Confluent Platform on Google Kubernetes Engine demo <https://docs.confluent.io/current/tutorials/examples/kubernetes/gke-base/docs/index.html>`__

.. |cluster-settings| image:: images/cluster-settings.png
   :align: middle
   :width: 80%

|k8s-service-name-long| to |ccloud| with |crep-full|
=====================================================

Overview
--------

.. include:: ../../docs/includes/replicator-cc-demo/overview.rst

.. figure:: images/operator-demo-phase-2.png
    :alt: operator

Demo Prerequisites
-------------------

The following applications or libraries are required to be installed and available in the system path in order to properly run the demo.

+------------------+-------------------+----------------------------------------------------------+
| Application      | Tested Version    | Info                                                     |
+==================+===================+==========================================================+
| ``kubectl``      | ``1.18.0``        | https://kubernetes.io/docs/tasks/tools/install-kubectl/  |
+------------------+-------------------+----------------------------------------------------------+
| ``helm``         | ``3.1.2``         | https://github.com/helm/helm/releases/tag/v3.1.2         |
+------------------+-------------------+----------------------------------------------------------+
| ``gcloud``       | ``286.0.0``       | https://cloud.google.com/sdk/install                     |
| ``GCP sdk core`` | ``2020.03.24``    |                                                          |
| ``GKE cluster``  | ``1.15.11-gke.1`` |                                                          |
+------------------+-------------------+----------------------------------------------------------+
| ``ccloud``       | ``v1.0.0``        | https://docs.confluent.io/current/cloud/cli/install.html |
+------------------+-------------------+----------------------------------------------------------+

.. include:: ../../docs/includes/helm3-requirement-note.rst

Running the Demo
----------------

.. warning:: This demo consumes real cloud resources on both |ccloud| and |gcp-long|.  To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all :ref:`resources are destroyed <quickstart-demos-operator-replicator-gke-cc-destroy>` after you are done evaluating the demonstration.  Refer to `Confluent Cloud <https://www.confluent.io/confluent-cloud/>`__ and `Google Cloud <https://cloud.google.com/pricing/>`__ pricing data for more information.  The |co| :ref:`Sizing Recommendations <co-env-sizing>` document contains information on required sizing for |co-long|.

Clone the `Confluent examples repository <https://github.com/confluentinc/examples>`__ and change directories on your terminal into the ``kubernetes/replicator-gke-cc`` directory.

.. sourcecode:: bash

    git clone https://github.com/confluentinc/examples.git
    cd examples/kubernetes/replicator-gke-cc

GKE Setup
~~~~~~~~~

In order to properly simulate a realistic replication scenario to |ccloud|, the demo requires a GKE Node Pool sufficiently large to support a 3 node clusters for both |ak| and |zk|.  In testing of this demonstration, a sufficient cluster consisted of 7 nodes of machine type ``h1-highmem-2``.  

.. tip:: The :ref:`examples-operator-gke-base-variable-reference` section can be used to control the size of the deployed resources in this demo.

If you wish to use an existing GKE cluster, and your ``kubectl`` client is already configured to operate with it, skip to the :ref:`quickstart-demos-operator-replicator-gke-cc-ccloud-setup` section of these instructions.

If you wish to create a new GKE cluster for this demo, the ``Makefile`` contains a function to assist you in creating a cluster, assuming you have your ``glcoud`` SDK properly configured to access your account.  If you wish to override the behavior of the create cluster function, see the :ref:`quickstart-demos-operator-replicator-gke-cc-ccloud-advanced-usage` section of this document.

To verify which GCP Project your ``gcloud`` SDK is currently configured to, run:

.. include:: ../../docs/includes/gcloud-config-list.rst

To create the standard cluster you can run the following:

.. sourcecode:: bash

    make gke-create-cluster

.. _quickstart-demos-operator-replicator-gke-cc-ccloud-setup:

|ccloud| Setup
~~~~~~~~~~~~~~~~~~~~~

.. include:: ../../docs/includes/replicator-cc-demo/ccloud-setup.rst

Preflight Checks
++++++++++++++++

Prior to running the demo you may want to verify the setup.

To verify your GKE cluster status:

.. sourcecode:: bash

    gcloud container clusters list

To verify that your ``kubectl`` command is configured with the proper context to control your GKE cluster, run:

.. sourcecode:: bash

    kubectl config current-context

The output of the previous command should be a name with the combination of your GKE project, the region, and the value of the ``Makefile`` variable ``GKE_BASE_CLUSTER_ID`` and your machine username, for example:

.. sourcecode:: bash

    kubectl config current-context
    gke_gkeproject_us-central1-a_cp-examples-operator-jdoe

Demo Execution
++++++++++++++

.. include:: ../../docs/includes/replicator-cc-demo/demo-execution.rst

Validate
~~~~~~~~

.. include:: ../../docs/includes/replicator-cc-demo/verify-demo.rst

.. _quickstart-demos-operator-replicator-gke-cc-destroy:

Destroy Resources
~~~~~~~~~~~~~~~~~

After you are done evaluating the results of the demo, you can destroy all the provisioned Kubernetes resources with:

.. sourcecode:: bash

    make destroy-demo

If you used the demo to create your cluster, you can destroy the GKE cluster with:

.. sourcecode:: bash

    make gke-destroy-cluster

Highlights
----------

.. include:: ../../docs/includes/replicator-cc-demo/highlight-connector-deployment.rst

.. include:: ../../docs/includes/deploy-jars-k8s.rst

.. _quickstart-demos-operator-replicator-gke-cc-ccloud-advanced-usage:

Advanced Usage
--------------

Customize GKE Cluster Creation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There are variables you can override and pass to the `make` command.  The following table shows the variables and their defaults.  The variables can be set on the ``make`` command, such as:

.. sourcecode:: bash

  GKE_BASE_ZONE=us-central1-b make gke-create-cluster

Or they can be exported to the current environment prior to running the make command:

.. sourcecode:: bash

    export GKE_BASE_ZONE=us-central1-b
    make gke-create-cluster

.. table:: Cluster Creation Variables

    +--------------------------+---------------+
    | Variable                 | Default       |
    +==========================+===============+
    | GKE_BASE_REGION          | us-central1   |
    +--------------------------+---------------+
    | GKE_BASE_ZONE            | us-central1-a |
    +--------------------------+---------------+
    | GKE_BASE_SUBNET          | default       |
    +--------------------------+---------------+
    | GKE_BASE_CLUSTER_VERSION | 1.13.7-gke.24 |
    +--------------------------+---------------+
    | GKE_BASE_MACHINE_TYPE    | n1-highmem-2  |
    +--------------------------+---------------+
    | GKE_BASE_IMAGE_TYPE      | COS           |
    +--------------------------+---------------+
    | GKE_BASE_DISK_TYPE       | pd-standard   |
    +--------------------------+---------------+
    | GKE_BASE_DISK_SIZE       | 100           |
    +--------------------------+---------------+

.. include:: ../../docs/includes/replicator-cc-demo/closing.rst
