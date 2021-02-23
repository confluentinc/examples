.. _ccloud-monitoring-producer-connectivity-problem:

Authorization Revoked
*********************

Using the |ccloud| CLI, revoke the producer's authorization to write to the topic.

This scenario will look at |ccloud| metrics from the Metrics API and client metrics from the client application's MBean object ``kafka.producer:type=producer-metrics,client-id=producer-1``.

Introduce failure scenario
^^^^^^^^^^^^^^^^^^^^^^^^^^

#. Delete the ACL allowing write to the topic, inserting your service account ID instead of ``184498``:

   .. code-block:: bash

      ccloud kafka acl delete --service-account 184498 --operation write  --topic '*' --allow

Diagnose the problem
^^^^^^^^^^^^^^^^^^^^

.. includes: ../includes/produce-failures.rst

Resolve failure scenario
^^^^^^^^^^^^^^^^^^^^^^^^

#. Add the ACL allowing write to the topic, inserting your service account ID instead of ``184498``:

   .. code-block:: bash

      ccloud kafka acl add --service-account 184498 --operation write  --topic '*' --allow


.. |Confluent Cloud Panel|
   image:: ../images/cloud-panel.png
   :alt: Confluent Cloud Panel

.. |Producer Connectivity Loss|
   image:: ../images/producer-connectivity-loss.png
   :alt: Producer Connectivity Loss
