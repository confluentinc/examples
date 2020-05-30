.. _replicator-to-cloud-configurations:

|crep-full| to |ccloud| Configurations
======================================

Whether you are migrating from on-prem to cloud or have a persistent "bridge to cloud" strategy, you can use |crep-full| to copy Kafka data to |ccloud|.
Learn the different ways to configure |crep| and |kconnect-long|.

.. figure:: images/replicator-to-ccloud.png

=======================
Brief Concepts Overview
=======================

Before diving into the different ways to configure |crep|, let's first reprise some basic concepts regarding |crep| and |kconnect-long|.
This will help you understand the logic for configuring |crep| because how the |kconnect-long| cluster is configured will affect how |crep| should be configured.

- |crep| is a Kafka connector and runs on Connect workers. Even the :ref:`Replicator executable <replicator_executable>` has a bundled Connect worker inside.
- There is an embedded consumer within |crep| that reads data from the origin cluster.
- |crep| is more specifically a source connector, and as with all source connectors, it leverages the Connect worker's embedded producer to write data to the destination cluster, which in this case is |ccloud|.
- A Connect cluster uses the admin client to create three Kafka topics for its own management, ``offset.storage.topic``, ``config.storage.topic``, and ``status.storage.topic``, and these are in the Kafka cluster that backs the Connect worker.


===================
Configuration Types
===================

The simplest configuration is where |crep| runs on a self-managed Connect cluster that is backed to the destination |ccloud| cluster.
This allows |crep| to leverage the default behavior of the Connect worker's admin client and embedded producer.

There are two configuration examples of where |crep| runs on a :ref:`connect-backed-destination`:

- :ref:`onprem-cloud-destination`
- :ref:`cloud-cloud-destination`

.. figure:: images/replicator-worker-destination.png

If you do not want your self-managed Connect cluster backed to the destination |ccloud| cluster, you can have a Connect cluster backed to the origin cluster instead.
This configuration is more complex because there are some additional overrides you will need to configure.

There are two configuration examples of where |crep| runs on a :ref:`connect-backed-origin`:

- :ref:`onprem-cloud-origin`
- :ref:`cloud-cloud-origin`

.. figure:: images/replicator-worker-origin.png


.. _connect-backed-destination:

=====================================
Connect Cluster Backed to Destination
=====================================

.. _onprem-cloud-destination:

On-prem to |ccloud| with Connect Backed to Destination
------------------------------------------------------

In this example, |crep| copies data from an on-prem Kafka cluster to |ccloud|, and |crep| runs on a Connect cluster backed to the destination |ccloud| cluster.

.. include:: includes/generic-subset.rst

.. figure:: images/onprem-ccloud-destination.png

Configure |kconnect-long|
^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: includes/connect-worker-to-destination-ccloud.rst 

Configure |crep|
^^^^^^^^^^^^^^^^

.. include:: includes/replicator-from-origin-onprem.rst

.. include:: includes/replicator-to-destination-ccloud.rst

Configure ACLs
^^^^^^^^^^^^^^

.. include:: includes/set-acls-destination.rst


.. _cloud-cloud-destination:

|ccloud| to |ccloud| with Connect Backed to Destination
-------------------------------------------------------

In this example, |crep| copies data from |ccloud| to |ccloud|, and |crep| runs on a Connect cluster backed to the destination |ccloud| cluster.

.. include:: includes/generic-subset.rst

.. figure:: images/ccloud-ccloud-destination.png

Configure |kconnect-long|
^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: includes/connect-worker-to-destination-ccloud.rst

Configure |crep|
^^^^^^^^^^^^^^^^

.. include:: includes/replicator-from-origin-ccloud.rst

.. include:: includes/replicator-to-destination-ccloud.rst

Configure ACLs
^^^^^^^^^^^^^^

.. include:: includes/set-acls-origin-and-destination.rst


.. _connect-backed-origin:

================================
Connect Cluster Backed to Origin
================================

.. _onprem-cloud-origin:

On-prem to |ccloud| with Connect Backed to Origin
-------------------------------------------------

In this example, |crep| copies data from an on-prem Kafka cluster to |ccloud|, and |crep| runs on a Connect cluster backed to the origin on-prem cluster.

.. include:: includes/generic-subset.rst

.. figure:: images/onprem-ccloud-origin.png

Configure |kconnect-long|
^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: includes/connect-worker-to-origin-onprem.rst

Configure |crep|
^^^^^^^^^^^^^^^^

.. include:: includes/replicator-from-origin-onprem.rst

.. include:: includes/replicator-to-destination-ccloud.rst

Configure ACLs
^^^^^^^^^^^^^^

.. include:: includes/replicator-overrides.rst

.. include:: includes/set-acls-destination.rst


.. _cloud-cloud-origin:

|ccloud| to |ccloud| with Connect Backed to Origin
--------------------------------------------------

In this example, |crep| copies data from |ccloud| to |ccloud|, and |crep| runs on a Connect cluster backed to the origin on-prem cluster.

.. include:: includes/generic-subset.rst

.. figure:: images/ccloud-ccloud-origin.png

Configure |kconnect-long|
^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: includes/connect-worker-to-origin-ccloud.rst

Configure |crep|
^^^^^^^^^^^^^^^^

.. include:: includes/replicator-from-origin-ccloud.rst

.. include:: includes/replicator-to-destination-ccloud.rst

.. include:: includes/replicator-overrides.rst

Configure ACLs
^^^^^^^^^^^^^^

.. include:: includes/set-acls-origin-and-destination.rst


==========================================================
Additional Resources
==========================================================

- For additional considerations on running |crep| to |ccloud|, refer to :ref:`cloud-migrate-topics`.
- To run a |ccloud| demo that showcases a hybrid Kafka cluster: one cluster is a self-managed Kafka cluster running locally, the other is a |ccloud| cluster, see :ref:`quickstart-demos-ccloud`..
- To find additional |ccloud| demos, see :ref:`Confluent Cloud Demos Overview<ccloud-demos-overview>`.
- For a practical guide to configuring, monitoring, and optimizing your |ak| client applications, see the `Best Practices for Developing Kafka Applications on Confluent Cloud <https://assets.confluent.io/m/14397e757459a58d/original/20200205-WP-Best_Practices_for_Developing_Apache_Kafka_Applications_on_Confluent_Cloud.pdf>`__ whitepaper.
- To run a |crep| tutorial with an active-active multi-datacenter design, with two instances of |crep-full| that copy data bidirectionally between the datacenters, see :ref:`replicator`.

