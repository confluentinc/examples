.. _ccloud-observability-general-request-rate-limits:

Request rate limits
********************

If request rate limits are hit, requests may be refused and clients may be throttled to keep the cluster stable. This throttling
would register as non-zero values for the producer client ``produce-throttle-time-max`` and
``produce-throttle-time-avg`` metrics and consumer client ``fetch-throttle-time-max`` and ``fetch-throttle-time-avg`` metrics.

#. Open `Grafana <localhost:3000>`__ and use the username ``admin`` and password ``password`` to login.

#. Navigate to the ``Confluent Cloud`` dashboard.

#. Check the ``Requests (rate)`` panel. If this panel is yellow, you have used 80% of your allowed requests; if it's red, you have used 90%.

   |Confluent Cloud Panel|

#. Scroll lower down on the dashboard to see a breakdown of where the requests are to in the ``Request rate`` stacked column chart.

   |Confluent Cloud Request Breakdown|

#. Reduce requests by adjusting producer batching configurations (``linger.ms``), consumer
   batching configurations (``fetch.max.wait.ms``), and shut down inactive clients.


.. |Confluent Cloud Panel|
   image:: ../images/cloud-panel.png
   :alt: Confluent Cloud Panel

.. |Confluent Cloud Request Breakdown|
   image:: ../images/cloud-request-rate-breakdown.png
   :alt: Confluent Cloud Request Breakdown