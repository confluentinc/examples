.. _quickstart-demos-operator-replicator-gke-cc:

Google Kubernetes Engine to |ccloud| with |crep-full|
=====================================================

Overview
--------

This example features a deployment of `Confluent Platform <https://www.confluent.io/product/confluent-platform/>`__ on `Google Kubernetes Engine (GKE) <https://cloud.google.com/kubernetes-engine/>`__ leveraging `Confluent Operator <https://docs.confluent.io/current/installation/operator/index.html>`__ and `Confluent Replicator <https://docs.confluent.io/current/connect/kafka-connect-replicator/index.html>`__, highlighting a data replication strategy to `Confluent Cloud <https://www.confluent.io/confluent-cloud/>`__.  Upon running this demo, you will have a GKE based |cp| deployment with simulated data replicating to your |ccloud| cluster.  We will verify the replication by running client applications against the |ccloud| cluster to view the simulated data originating in the source GKE cluster.

If you'd like a primer on running |co-long| in GKE with lower resource requirements, see the `Confluent Platform on Google Kubernetes Engine demo <https://docs.confluent.io/current/tutorials/examples/kubernetes/gke-base/docs/index.html>`__.  

The major components of this demo are:

* A |ccloud| Environment and |ak| Cluster
* A Kubernetes cluster running on GKE.
* |co-long| which is used to manage the following |cp| components

  * A 3 node |zk| cluster
  * A 3 node |ak| cluster
  * A single node |crep|
  * A single node |sr|
  * A single node |kconnect-long|
  * |c3|
  * One instance of `kafka-connect-datagen <https://github.com/confluentinc/kafka-connect-datagen>`__ to produce mock stock trading data

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

.. warning:: In testing, issues were experienced with ``helm`` versions > than 2.12.3.  It's highly recommended that the demo be ran specifically with ``helm`` version ``2.12.3``.

Running the Demo
----------------

.. warning:: This demo uses the real GCP SDK to launch real resources. To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done evaluating the demonstration.  Optionally, refer to the |co| :ref:`Sizing Recommendations <co-env-sizing>` document and the :ref:`examples-operator-gke-base-variable-reference` section for more information on required resources for running |cp| on Kubernetes.

Setup
~~~~~

Clone the `Confluent examples repository <https://github.com/confluentinc/examples>`__ and change directories on your terminal into the ``replicator-gke-cc`` directory.

.. sourcecode:: bash

    git clone git@github.com:confluentinc/examples.git
    cd examples/kubernetes/replicator-gke-cc

GKE Setup
+++++++++

In order to properly simulate a realistic replication scenario to |ccloud|, the demo requires a GKE Node Pool sufficiently large to support a 3 node clusters for both |ak| and |zk|.  In testing of this demonstration, a sufficient cluster consisted of 7 nodes of machine type ``h1-highmem-2``.  If you wish to use an existing GKE cluster, and your ``kubectl`` tool is already configured to operate with it, skip to the :ref:`quickstart-demos-operator-replicator-gke-cc-ccloud-setup` section of these instructions.

If you wish to create a new GKE cluster for this demo, the ``Makefile`` contains a ``make`` function to assist you in creating a cluster, assuming you have your ``glcoud`` SDK properly configured to access your account.  If you wish to override the behavior of the create cluster function, see the :ref:`quickstart-demos-operator-replicator-gke-cc-ccloud-advanced-usage` section of this document.

To verify which GCP Project your ``gcloud`` SDK is currently configured to, run:

.. sourcecode:: bash

    gcloud config list --format 'value(core.project)'

To create the standard cluster you can run the following:

.. sourcecode:: bash

    make gke-create-cluster

.. _quickstart-demos-operator-replicator-gke-cc-ccloud-setup:

Confluent Cloud Setup
+++++++++++++++++++++

This demonstration requires that you have a |ccloud| account and a |ak| cluster ready for use.  The `Confluent Cloud <https://www.confluent.io/confluent-cloud/>`__ home page can help you get setup with your own account if you do not yet have access.   Once you have your account, see the `Confluent Cloud Quick Start <https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html>`__ to get your first cluster up and running.  If you are creating a new cluster, it is advised to create it within the same Cloud Provider and region as this demo.  This demonstration runs on top of Google Cloud Platform (GCP) and by default in the ``us-central1`` region.

After you have established the |ccloud| cluster you are going to use for the demo, you will need the public Bootstrap Server as well as an API Key and it's Secret to configure client connectivity.

You can use the ``ccloud`` CLI retrieve the Bootstrap Server value for your cluster.

.. tip:: You can also view the Bootstrap Server value on the Confluent Cloud UI under the **Cluster settings**.

#.  If you haven't already, `install the ccloud CLI <https://docs.confluent.io/current/quickstart/cloud-quickstart/index.html#step-2-install-the-ccloud-cli>`__

#.  Log in to your |ccloud| cluster.

    ::

        ccloud login --url https://confluent.cloud

    Your output should resemble:

    ::

        Enter your Confluent credentials:
        Email: jdoe@myemail.io
        Password:

        Logged in as jdoe@myemail.io
        Using environment t118 ("default")

#.  List your available |ak| clusters.

    ::

        ccloud kafka cluster list

    This should produce a list of clusters you have access to:

    ::

              Id      |          Name          | Provider |   Region    | Durability | Status
        +-------------+------------------------+----------+-------------+------------+--------+
            lkc-xmm5g | cluster-one            | gcp      | us-central1 | LOW        | UP
            lkc-kngnv | example-cluster-two    | gcp      | us-central1 | LOW        | UP
          * lkc-m85m7 | replicator-gke-cc-demo | gcp      | us-central1 | LOW        | UP

#.  Describe the cluster to obtain the Bootstrap Server

    ::

        ccloud kafka cluster describe lkc-m85m7

    This will produce a detailed view of the cluster.  The ``Endpoint`` field contains the Boostrap Server value

    ::

        +-------------+------------------------------------------------------------+
        | Id          | lkc-m85m7                                                  |
        | Name        | replicator-gke-cc-demo                                     |
        | Ingress     |                                                        100 |
        | Egress      |                                                        100 |
        | Storage     |                                                       5000 |
        | Provider    | gcp                                                        |
        | Region      | us-central1                                                |
        | Status      | UP                                                         |
        | Endpoint    | SASL_SSL://pkc-4n7de.us-central1.gcp.stag.cpdev.cloud:9092 |
        | ApiEndpoint | https://pkac-lq8w6.us-central1.gcp.stag.cpdev.cloud        |
        +-------------+------------------------------------------------------------+

The ``ccloud`` CLI allows you to create API Keys to be used with client applications.

.. tip:: You can also create the API Key using the
         :ref:`Confluent Cloud UI <cloud-quick-create-api-key>`.

To create a new API Key:

    ::

    ccloud api-key create --resource lkc-m85m7

The tool will display a new Key and secret as below.  You will need to save these values elsewhere as they cannot be retrieved later.

    ::

    Save the API key and secret. The secret is not retrievable later.
    +---------+------------------------------------------------------------------+
    | API Key | LD35EM2YJTCTRQRM                                                 |
    | Secret  | 67JImN+9vk+Hj3eaj2/UcwUlbDNlGGC3KAIOy5JNRVSnweumPBUpW31JWZSBeawz |
    +---------+------------------------------------------------------------------+

To configure the demo to access your |ccloud| account, we are going to create a `Helm Chart <https://helm.sh/docs/chart_template_guide/>`__ values file, which the demo looks for in a particular location to pass to ``helm`` commands to weave your cloud account details into the configuration of the |cp| configurations.

Create a values file by executing the following command, first replacing the ``{{ mustache bracket }}`` values for  ``bootstrapEndpoint``, ``username``, and ``password`` with your relevant values obtained above. 

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

    kubectl config current-context
    gke_gkeproject_us-central1-a_cp-examples-operator-jdoe

Run
~~~

To run the automated demo run (estimated running time, 8 minutes):

.. sourcecode:: bash

    make demo

The last output message you should see is::

    ✔ Replicator GKE->CC Demo running

Validate
~~~~~~~~

Coming soon...

Delete Resources
~~~~~~~~~~~~~~~~

After you are done evaluating the results of the demo, you can destroy all the provisioned Kubernetes resources with:

.. sourcecode:: bash

    make destroy-demo

If you used the demo to create your cluster, you can destroy the GKE cluster with:

.. sourcecode:: bash

    make gke-destroy-cluster

Highlights
----------

Coming soon...

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

Troubleshooting
---------------

- If you observe that the replicated offsets do not match in the source and destination cluster, the destination cluster may have existed prior to starting the cluster in situations where you may have restarted the demonstration.  To see the full demonstration function properly, use a new cluster or delete and recreate the destination topic prior to running the demo.


