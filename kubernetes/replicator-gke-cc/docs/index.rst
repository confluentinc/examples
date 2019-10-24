.. _quickstart-demos-operator-replicator-gke-cc:

Google Kubernetes Engine to |ccloud| with |crep-full|
=====================================================

Overview
--------

This example features a deployment of |cp| on Google Kubernetes Engine (GKE) leveraging |co-long| and |crep-full|, highlighting a data replication strategy to |ccloud|.  Upon running this demo, you will have a GKE based |cp| deployment with simulated data replicating to your |ccloud| cluster.  We will verify the replication by running client applications against the |ccloud| cluster to view the simulated data originating in the source GKE cluster.

This demonstration builds off of the `Confluent Platform on Google Kubernetes Engine demo <https://docs.confluent.io/current/tutorials/examples/kubernetes/gke-base/docs/index.html>`__.  If you'd like a primer on running |co-long| in GKE with lower resource requirements, you can start with that demo. 

The major components of this demo are:

* A |ccloud| environment and |ak| cluster
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

+------------------+----------------+----------------------------------------------------------+
| Application      | Tested Version | Info                                                     |
+==================+================+==========================================================+
| ``kubectl``      | ``1.14.3``     | https://kubernetes.io/docs/tasks/tools/install-kubectl/  |
+------------------+----------------+----------------------------------------------------------+
| ``helm``         | ``2.12.3``     | https://helm.sh/docs/using_helm/#install-helm            |
+------------------+----------------+----------------------------------------------------------+
| ``gcloud``       | ``267.0.0``    |  https://cloud.google.com/sdk/install                    |
| ``GCP sdk core`` | ``2019.10.15`` |                                                          |
+------------------+----------------+----------------------------------------------------------+
| ``ccloud``       | ``v0.185.0``   | https://docs.confluent.io/current/cloud/cli/install.html |
+------------------+----------------+----------------------------------------------------------+

.. warning:: In testing issues with ``helm`` versions > than 2.12.3 have been observed.  It's highly recommended that the demo be ran specifically with ``helm`` version ``2.12.3``.

Running the Demo
----------------

.. warning:: This demo uses the real GCP SDK to launch real resources. To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done evaluating the demonstration.  Optionally, refer to the |co| :ref:`Sizing Recommendations <co-env-sizing>` document and the :ref:`examples-operator-gke-base-variable-reference` section for more information on required resources for running |cp| on Kubernetes.
 
Setup
-----

Clone the `Confluent examples repository <https://github.com/confluentinc/examples>`__ and change directories on your terminal into the ``replicator-gke-cc`` directory.

.. sourcecode:: bash

    git clone git@github.com:confluentinc/examples.git
    cd examples/kubernetes/replicator-gke-cc

GKE Setup
+++++++++

In order to properly simulate a realistic replication scenario to |ccloud|, the demo requires a GKE Node Pool sufficiently large to support 3 node |zk| and 3 node |ak| clusters.  In testing this demonstration, a sufficient cluster consisted of 7 nodes of machine type ``h1-highmem-2``.  If you wish to use an existing GKE cluster, and your ``kubectl`` tool is already configured to operate with it, skip to the :ref:`quickstart-demos-operator-replicator-gke-cc-ccloud-setup` section of these instructions.

The demo contains a ``make`` function to assist you in creating a cluster in GKE assuming you have your ``glcoud`` SDK properly configured to access your account.  If you wish to override the behavior of the create cluster function, see the :ref:`quickstart-demos-operator-replicator-gke-cc-ccloud-advanced-usage` section of this document.

To verify which GCP Project your ``gcloud`` SDK is currently configured to, run:

.. sourcecode:: bash

    gcloud config list --format 'value(core.project)'

To create the standard cluster you can run the following:

.. sourcecode:: bash

    make gke-create-cluster



.. _quickstart-demos-operator-replicator-gke-cc-ccloud-setup:

Confluent Cloud Setup
+++++++++++++++++++++

This demonstration requires that you have a |ccloud| account and |ak| cluster ready for use.  See https://www.confluent.io/confluent-cloud/ to get setup with your own account if you do not yet have access.   Once you have your account, see the `Confluent Cloud Quick Start <https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html>`__ to get your first cluster up and running.  If you are creating a new cluster, it is advised to create it within the same Cloud Provider and region as this demo.  This demonstration runs on top of Google Cloud Platform (GCP) and by default in the ``us-central1`` region.

After you have established the |ccloud| cluster you are going to use for the demo, take note of the API Key and Secret clients will use to access the |ccloud| cluster, you will need the values in a momemnt to configure the demo.  See `Create an API Key <https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html#step-4-create-an-api-key>`__ for more details.

To configure the demo to access your |ccloud| account, we are going to create a `Helm Chart values file <https://helm.sh/docs/chart_template_guide/>`__, which the demo looks for in a particular location to pass to ``helm`` commands to weave your cloud account details into the configuration of the |cp| configurations.

Create a values file by executing the following command, first replacing the ``{{ mustache bracket }}`` values for  ``bootstrapEndpoint``, ``username``, and ``password`` with your relevant values.  You can obtain these values from the |ccloud| web console in the CLI & client configuration section.

.. sourcecode:: bash

    cat <<'EOF' > ./cfg/my-values.yaml
    destinationCluster: &destinationCluster
      name: replicator-gke-cc-demo
      tls:
        enabled: true
        internal: true
        authentication:
          type: plain
      bootstrapEndpoint: {{ cloud bootstrap server connection }}
      username: {{ cloud API key }}
      password: {{ cloud API secret }}

    controlcenter:
      dependencies:
        monitoringKafkaClusters:
        - <<: *destinationCluster
    
    replicator:
      replicas: 1
      dependencies:
        kafka:
          <<: *destinationCluster
    EOF

Prior to running the demo you may want to verify the setup.

To verify your GKE cluster status:

.. sourcecode:: bash

    gcloud container clusters list

To verify that your ``kubectl`` command is configured with the proper context to control your GKE cluster, run:

.. sourcecode:: bash

    kubectl config current-context

The output of the previous command should be a name with the combination of your GKE project, the region, and the value of the ``Makefile`` variable ``GKE_BASE_CLUSTER_ID`` and your machine username, for example:

.. sourcecode:: bash

    ➜ kubectl config current-context
    gke_gkeproject_us-central1-a_cp-examples-operator-jdoe

Run
---

To run the automated demo run (estimated running time, 8 minutes):

.. sourcecode:: bash

    make demo

The last output message you should see is::

	✔ Replicator GKE->CC Demo running

Validate
--------

Coming soon...

Highlights
----------

Coming soon...

.. _quickstart-demos-operator-replicator-gke-cc-ccloud-advanced-usage:

Advanced Usage
--------------

  There are variables you can override and pass to the `make` command.  The following table shows the variables and their defaults.  The variables can be set on the ``make`` command, such as:

.. sourcecode:: bash

  GKE_BASE_ZONE=us-central1-b make gke-create-cluster

Or they can be exported to the current environment prior to running the make command:

.. sourcecode:: bash

    export GKE_BASE_ZONE=us-central1-b
    make gke-create-cluster

GKE Create Cluster variables
++++++++++++++++++++++++++++

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


Troubleshooting
---------------

WIP

Offsets may not match up if the destination cluster (|ccloud|) topic isn't recreated prior to running.
