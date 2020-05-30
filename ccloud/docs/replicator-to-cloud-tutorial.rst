.. _replicator-to-cloud-tutorial:

|crep| to |ccloud| Tutorial
===========================

This Docker-based tutorial shows you several ways to deploy |crep| where the destination Kafka cluster is |ccloud|.

|crep| is a source connector, and so the easiest deployment model is where |crep| runs on a self-managed connect cluster that is backed to the destination |ccloud| cluster, which means that the connect workers are using the destination |ccloud| cluster for its connect topics `offset.storage.topic`, `config.storage.topic`, and `status.storage.topic`.

:ref:`Example 1 <onprem-cloud-destination>`: on-prem to |ccloud| where |crep| runs on a connect cluster backed to the destination |ccloud| cluster 
:ref:`Example 2 <cloud-cloud-destination>`: |ccloud| to |ccloud| where |crep| runs on a connect cluster backed to the destination |ccloud| cluster

However, if you do not want to back your self-managed connect cluster to the destination |ccloud| cluster, you can also have a connect cluster backed to the origin cluster instead of |ccloud|, which means that the connect workers are using the origin cluster for its connect topics `offset.storage.topic`, `config.storage.topic`, and `status.storage.topic`.
This deployment model is more complex because there are some additional overrides you will need to configure.

:ref:`Example 3 <onprem-cloud-origin>`: on-prem to |ccloud| where |crep| runs on a connect cluster backed to the origin on-prem cluster
:ref:`Example 4 <cloud-cloud-origin>`: |ccloud| to |ccloud| where |crep| runs on a connect cluster backed to the origin |ccloud| cluster


.. _onprem-cloud-destination:

==========================================================
On-prem to |ccloud|: Connect Cluster backed to Destination
==========================================================

In this example, |crep| copies data from an on-prem Kafka cluster to |ccloud|, and |crep| runs on a connect cluster backed to the destination |ccloud| cluster.

.. include:: includes/generic-subset.rst

Connect Worker Configuration
----------------------------

.. include:: includes/connect-worker-to-ccloud-destination.rst 

|crep| Configuration
--------------------

.. include:: includes/replicator-from-on-prem-origin.rst

.. include:: includes/replicator-to-ccloud-destination.rst

|crep| Authorization
--------------------

.. include:: includes/set-acls-destination.rst

.. _cloud-cloud-destination:

===========================================================
|ccloud| to |ccloud|: Connect Cluster backed to Destination
===========================================================

In this example, |crep| copies data from |ccloud| to |ccloud|, and |crep| runs on a connect cluster backed to the destination |ccloud| cluster.

.. include:: includes/generic-subset.rst

Connect Worker Configuration
----------------------------

.. include:: includes/connect-worker-to-ccloud-destination.rst

|crep| Configuration
--------------------

.. include:: includes/replicator-from-ccloud-origin.rst

.. include:: includes/replicator-to-ccloud-destination.rst

|crep| Authorization
--------------------

.. include:: includes/set-acls-destination.rst

.. include:: includes/set-acls-origin.rst

.. _onprem-cloud-origin:

=====================================================
On-prem to |ccloud|: Connect Cluster backed to Origin
=====================================================

In this example, |crep| copies data from an on-prem Kafka cluster to |ccloud|, and |crep| runs on a connect cluster backed to the origin on-prem cluster.

.. include:: includes/generic-subset.rst

Connect Worker Configuration
----------------------------

.. include:: includes/connect-worker-to-origin.rst

|crep| Configuration
--------------------

.. include:: includes/replicator-from-onprem-origin.rst

.. include:: includes/replicator-to-ccloud-destination.rst

.. include:: includes/replicator-overrides.rst

|crep| Authorization
--------------------

.. include:: includes/set-acls-destination.rst

.. _cloud-cloud-origin:

======================================================
|ccloud| to |ccloud|: Connect Cluster backed to Origin
======================================================

In this example, |crep| copies data from |ccloud| to |ccloud|, and |crep| runs on a connect cluster backed to the origin on-prem cluster.

.. include:: includes/generic-subset.rst

Connect Worker Configuration
----------------------------

.. include:: includes/connect-worker-to-ccloud-origin.rst

|crep| Configuration
--------------------

.. include:: includes/replicator-from-on-prem-origin.rst

.. include:: includes/replicator-to-ccloud-destination.rst

.. include:: includes/replicator-overrides.rst

|crep| Authorization
--------------------

.. include:: includes/set-acls-destination.rst

.. include:: includes/set-acls-origin.rst
