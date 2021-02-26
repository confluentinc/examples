.. _ccloud-observability-general-request-rate-limit:

Request rate limits
********************

If request limits are hit, requests may be refused and clients may be throttled to keep the cluster stable. This throttling
would register as non-zero values for the producer client ``produce-throttle-time-max`` and
``produce-throttle-time-avg`` metrics and consumer client ``fetch-throttle-time-max`` and ``fetch-throttle-time-avg`` metrics.

#. Open `Grafana <localhost:3000>`__ and use the username ``admin`` and password ``password`` to login.

#. Navigate to the ``Confluent Cloud`` dashboard.

#. Check the ``Requests (rate)`` panel. If this panel is yellow, you have used 80% of your allowed requests; if it's red, you have used 90%.

   |Confluent Cloud Panel|

#. See a breakdown of where the requests are to with the ```` panel.

   |Confluent Cloud Request Breakdown|

#. To reduce usage on this dimension, you can adjust producer batching configurations (``linger.ms``), consumer
   client batching configurations (``fetch.max.wait.ms``), and shut down otherwise inactive clients.


.. |Confluent Cloud Panel|
   image:: ../images/cloud-panel.png
   :alt: Confluent Cloud Panel

.. |Confluent Cloud Request Breakdown|
   image:: ../images/cloud-request-rate-breakdown.png
   :alt: Confluent Cloud Request Breakdown