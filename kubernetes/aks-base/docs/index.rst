.. _quickstart-demos-operator-aks:


.. |k8s-service-name-long| replace:: Azure Kubernetes Service
.. |k8s-service-name| replace:: AKS

|cp| on |k8s-service-name-long|
======================================

.. include:: ../../docs/includes/base-demo/overview.rst

Prerequisites
-------------
The following applications or libraries are required to be installed and available in the system path in order to properly run the demo.

+------------------+----------------+-------------------------------------------------------------------------------------+
| Application      | Tested Version | Info                                                                                |
+==================+================+=====================================================================================+
| ``kubectl``      | ``1.18.0``     | https://kubernetes.io/docs/tasks/tools/install-kubectl/                             |
+------------------+----------------+-------------------------------------------------------------------------------------+
| ``helm``         | ``3.1.2``      | https://github.com/helm/helm/releases/tag/v3.1.2                                    |
+------------------+----------------+-------------------------------------------------------------------------------------+
| ``az``           | ``2.10.1``     |  https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest |
+------------------+----------------+-------------------------------------------------------------------------------------+

.. include:: ../../docs/includes/helm-requirement-note.rst

Running the Demo
----------------

.. warning:: This demo uses the real Azure CLI to launch real resources. To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done evaluating the demonstration.  Optionally, refer to the |co| `Sizing recommendations <https://docs.confluent.io/operator/current/co-plan.html#co-env-sizing>`__ document and the :ref:`examples-operator-aks-base-variable-reference` section for more information on required resources for running |cp| on Kubernetes.

 
.. _quickstart-demos-operator-aks-setup:

Setup
*****

.. include:: ../../docs/includes/aks-cli-setup.rst

Clone the Confluent examples repository and change directories on your terminal into the ``aks-base`` directory.

.. sourcecode:: bash

    git clone https://github.com/confluentinc/examples.git
    cd examples/kubernetes/aks-base

This demo requires a Kubernetes Cluster and ``kubectl`` context configured properly to manage it.

The remaining steps in the **Setup** section of the instructions help you build a Kubernetes cluster on |k8s-service-name-long| (|k8s-service-name|).  If you already have a cluster you wish to use for the demo, you can skip to the :ref:`examples-operator-aks-base-validate` section of these instructions.

To select the Azure Resource Group in which a new cluster will be created, set the variable ``AZ_RESOURCE_GROUP`` accordingly in the command below.

.. note::

    For specific details on how the cluster will be created (size, region, zone, etc...), view the :ref:`examples-operator-aks-base-variable-reference` section of these instructions.  You may also use these variables to modify the default behavior of the demo create cluster functionality.

To create the cluster, run the following (estimated running time, 4 minutes):

.. sourcecode:: bash

    export AZ_RESOURCE_GROUP={{ azure resource group name }}
    make aks-create-cluster

Verify that ``az`` has created the cluster properly::

    ...

    provisioningState: Succeeded
    sku:
      name: Basic
      tier: Free
    tags: null
    type: Microsoft.ContainerService/ManagedClusters
    
    ...

    az aks get-credentials --only-show-errors --resource-group confluent-operator-demo --name cp-examples-operator-user --context aks_confluent-operator-demo_centralus_cp-examples-operator-user
    Merged "aks_confluent-operator-demo_centralus_cp-examples-operator-user" as current context in /Users/user/.kube/config
    ✔  ++++++++++ AKS Cluster Created

.. _examples-operator-aks-base-validate:

Validate
********

The demo uses ``kubectl`` to control the cluster.  To verify that your local ``kubectl`` configured as intended, run:

.. sourcecode:: bash

    kubectl config current-context

The context should contain the proper region and cluster name.  If you used the demo ``aks-create-cluster`` function to create your cluster, the context name should have the format: ``aks_<azure_resource_group>_<region>_<cp-examples-operator>-<username>``

.. _examples-operator-aks-base-run:

Run
***

To deploy |cp| run (estimated running time, 7 minutes):

.. sourcecode:: bash

    make demo

The last output message you should see is::

	✔ AKS Base Demo running

.. _examples-operator-aks-verify-confluent-platform:

Verify 
******

.. include:: ../../docs/includes/base-demo/verify-demo.rst

Highlights 
**********

.. _examples-operator-aks-base-configuration:

Service Configurations
``````````````````````

The |cp| Helm Charts deliver a reasonable base configuration for most deployments.  What is left to the user is the 'last mile' of configuration specific to your environment.  For this example we specify the non-default configuration in the :devx-examples:`values.yaml|kubernetes/aks-base/cfg/values.yaml` file.   The YAML file facilitates a declarative infastructure approach, but can also be useful for viewing non-default configuration in a single place, bootstrapping a new environment, or sharing in general.

The following is an example section of the ``values.yaml`` file showing how |ak| server properties (``configOverrides``) can be configured using Helm Charts.  The example also shows a YAML anchor (``<<: *cpImage``) to promote reuse within the YAML file itself.  See the :devx-examples:`values.yaml|kubernetes/aks-base/cfg/values.yaml` for further details.

.. include:: ../../docs/includes/base-demo/highlight-service-configs.rst

Remaining configuration details are specificied in individual ``helm`` commands. An example is included below showing the setting to actually enable zookeeper deployment with the ``--set`` argument on the ``helm upgrade`` command.  See the :devx-examples:`Makefile|kubernetes/aks-base/Makefile-impl` for the full commands.

.. sourcecode:: bash

  helm upgrade --install --namespace operator --set zookeeper.enabled=true ... 

.. _examples-operator-aks-base-client-configurations:

.. include:: ../../docs/includes/base-demo/highlight-client-configs.rst

.. _examples-operator-aks-base-connector-deployments:

.. include:: ../../docs/includes/base-demo/highlight-connector-deployments.rst

.. _examples-operator-aks-base-tear-down:

Tear down
*********

To tear down the |cp| components inside the cluster, run the following (estimated running time, 4 minutes):

.. sourcecode:: bash

  make destroy-demo

You can verify that all resources are removed with::

  kubectl -n operator get all

If you used the example to create the Kubernetes cluster for you, destroy the cluster with (estimated running time, 3 minutes):

.. sourcecode:: bash

  make aks-destroy-cluster

Advanced Usage
**************

.. _examples-operator-aks-base-variable-reference:

Variable Reference
``````````````````

.. include:: ../../docs/includes/aks-custom-variables.rst
