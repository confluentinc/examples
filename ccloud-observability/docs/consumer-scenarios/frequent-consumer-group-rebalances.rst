.. _ccloud-observability-consumer-scenarios-frequent-consumer-group-rebalances:

Frequent consumer group rebalances
**********************************

Consumer group rebalances are a natural event in |ak|, but negative effects happen when a group is
rebalancing too often.

This scenario will look at metrics from various sources. Consumer lag metrics are pulled from the
`kafka-lag-exporter <https://github.com/lightbend/kafka-lag-exporter>`__ container, a scala open source project
that collects data about consumer groups and presents them in a Prometheus scrapable format. Metrics
about |ccloud| cluster resource usage are pulled from the Metrics API endpoints. Consumer client metrics
are pulled from the client application’s MBean object ``kafka.consumer:type=consumer-fetch-manager-metrics,client-id=<client_id>``.

Introduce failure scenario
^^^^^^^^^^^^^^^^^^^^^^^^^^

Diagnose the problem
^^^^^^^^^^^^^^^^^^^^

#. Open `Grafana <localhost:3000>`__ and login with the username ``admin`` and password ``password``.

#. Navigate to the ``Consumer Client Metrics`` dashboard. Wait 2 minutes and then observe:

Resolve failure scenario
^^^^^^^^^^^^^^^^^^^^^^^^
