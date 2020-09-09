.. _ccloud-monitoring:

Monitoring and measuring performance in Confluent Cloud
=======================================================

Performance monitoring provides a quantitative account of how each component is
doing. This monitoring is important once you’re in production, because
production environments are dynamic–that is, data profiles may change, you may
add new clients, and you may enable new features. Ongoing monitoring is as much
about identifying and responding to potential failures as it is about ensuring
the services goals are consistently met even as the production environment
changes.

Before you go into production, ensure you have a robust monitoring system in
place for all of the producers, consumers, topics, and any other |ak| or
Confluent components you are using.

This pages includes the information you will need to configure a robust
performance monitoring system when working with |ccloud|.


Metrics API
-----------

The `Confluent Cloud Metrics API
<https://docs.confluent.io/current/cloud/metrics-api.html>`__ provides
programmatic access to actionable metrics for your |ccloud| deployment. You can
get server-side metrics for the Confluent managed services, but you can't get
client-side metrics using the Metrics API (see :ref:`Producers
<ccloud-monitoring-producers>` and :ref:`Consumers
<ccloud-monitoring-consumers>` for client-side metrics).

The metrics are enabled by default, and any authorized user can get self-serve
access to them. The metrics are also aggregated at the topic level and cluster
level, which is useful for monitoring overall usage and performance, especially
since the metrics relate to billing. Confluent recommends using the Metrics API
to query metrics at the following granularities (other resolutions are available
if needed):

-  Bytes produced per minute grouped by topic

-  Bytes consumed per minute grouped by topic

-  Max retained bytes per hour over two hours for a given topic

-  Max retained bytes per hour over two hours for a given cluster

The following are examples of metrics at each level:

.. tabs::

   .. tab:: Topic level

      Here is the number of bytes produced per minute for a topic called ``test-topic``:

      .. code-block:: text

         {
            "data": [
                  {
                     "timestamp": "2019-12-19T16:01:00Z",
                     "metric.label.topic": "test-topic",
                     "value": 203.0
                  },
                  {
                     "timestamp": "2019-12-19T16:02:00Z",
                     "metric.label.topic": "test-topic",
                     "value": 157.0
                  },
                  {
                     "timestamp": "2019-12-19T16:03:00Z",
                     "metric.label.topic": "test-topic",
                     "value": 371.0
                  },
                  {
                     "timestamp": "2019-12-19T16:04:00Z",
                     "metric.label.topic": "test-topic",
                     "value": 288.0
                  }
            ]
         }

   .. tab:: Cluster level

      Here is the max retained bytes per hour over two hours for a |ccloud| cluster:

      .. code-block:: text

         {
            "data": [
               {
                     "timestamp": "2019-12-19T16:00:00Z",
                     "value": 507350.0
               },
               {
                     "timestamp": "2019-12-19T17:00:00Z",
                     "value": 507350.0
               }
            ]
         }

You can retrieve the metrics easily over the internet using HTTPS, capturing
them at regular intervals to get a time series and an operational view of
cluster performance. You can integrate the metrics into any cloud provider
monitoring tools like `Azure Monitor
<https://azure.microsoft.com/en-us/services/monitor/#product-overview>`__,
`Google Cloud’s operations suite
<https://cloud.google.com/products/operations>`__ (formerly Stackdriver), or
`Amazon CloudWatch <https://aws.amazon.com/cloudwatch/>`__, or into existing
monitoring systems like `Prometheus <https://prometheus.io/>`__ and `Datadog
<https://www.datadoghq.com/>`__, and then plot them in a time series graph to
see usage over time. When writing your own application to use the Metrics API,
see the `full API specification <https://api.telemetry.confluent.cloud/docs>`__
to use advanced features.


Client JMX Metrics
------------------

|ak| applications expose some internal Java Management Extensions (JMX) metrics,
and many users run JMX exporters to feed the metrics into their monitoring
systems. You can retrieve JMX metrics for your client applications and the
services you manage (though not for the Confluent-managed services, which are
not directly exposed to users) by starting your |ak| client applications with
the ``JMX_PORT`` environment variable configured. There are many `Kafka-internal
metrics <https://docs.confluent.io/current/kafka/monitoring.html>`__ that are
exposed through JMX to provide insight on the performance of your applications.


.. _ccloud-monitoring-producers:

Producers
---------

Throttling
~~~~~~~~~~

Depending on your |ccloud| service plan, you are limited to certain
throughput rates for produce (write). If your client applications exceed the
produce rates, the quotas on the brokers will detect it and the client
application requests will be throttled by the brokers. It’s important to ensure
your producers are well behaved. If they are being throttled, consider the
following two options:

- *First option*: Make modifications to the application to optimize its
  throughput, if possible. For more information on how to optimize throughput, see
  :ref:`optimizing-for-throughput`.

- *Second option*: Upgrade to a cluster configuration with higher limits. In
  |ccloud|, you can choose from Standard and Dedicated clusters, and Dedicated
  clusters are customizable for higher limits. The Metrics API can give you some
  indication of throughput from the server side, but it doesn’t provide throughput
  metrics on the client side. To get throttling metrics per producer, monitor the
  following client JMX metrics:

  .. list-table::
     :widths: 50 50
     :header-rows: 1
     :class: verticaltable

     * - Metric
       - Description
     * - ``kafka.producer:type=producer-metrics,client-id=([-.w]+),name=produce-throttle-time-avg``
       - The average time in ms that a request was throttled by a broker
     * - ``kafka.producer:type=producer-metrics,client-id=([-.w]+),name=produce-throttle-time-max``
       - The maximum time in ms that a request was throttled by a broker


User Processes
~~~~~~~~~~~~~~

To further tune the performance of your producer, monitor the producer
time spent in user processes if the producer has non-blocking code to
send messages. Using the ``io-ratio`` and ``io-wait-ratio`` metrics
described below, user processing time is the fraction of time not spent
in either of these. If time in these are low, then the user processing
time may be high, which keeps the single producer I/O thread busy. For
example, you can check if the producer is using any callbacks, which are
invoked when messages have been acknowledged and run in the I/O thread:

.. list-table::
   :widths: 50 50
   :header-rows: 1
   :class: verticaltable

   * - Metric
     - Description
   * - ``kafka.producer:type=producer-metrics,client-id=([-.w]+),name=io-ratio``
     - Fraction of time that the I/O thread spent doing I/O
   * - ``kafka.producer:type=producer-metrics,client-id=([-.w]+),name=io-wait-ratio``
     - Fraction of time that the I/O thread spent waiting


.. _ccloud-monitoring-consumers:

Consumers
---------

.. _throttling-1:

Throttling
~~~~~~~~~~

Depending on your |ccloud| service plan, you are limited to
certain throughput rates for consume (read). If your client applications
exceed these consume rates, the quotas on the brokers will detect it and
the brokers will throttle the client application requests. It’s
important to ensure your consumers are well behaved, and if they are
being throttled, consider two options:


- *First option*: Make modifications to the application to optimize its
  throughput, if possible For more information on how to optimize throughput, see
  :ref:`optimizing-for-throughput`.

- *Second option*: Upgrade to a cluster configuration with higher limits. In
  |ccloud|, you can choose from Standard and Dedicated clusters, and Dedicated
  clusters are customizable for higher limits. The Metrics API can give you some
  indication of throughput from the server side, but it doesn’t provide
  throughput metrics on the client side. To get throttling metrics per consumer,
  monitor the following client JMX metrics:

.. list-table::
   :widths: 50 50
   :header-rows: 1
   :class: verticaltable

   * - Metric
     - Description
   * - ``kafka.consumer:type=consumer-fetch-manager-metrics,client-id=([-.w]+),name=fetch-throttle-time-avg``
     - The average time in ms that a broker spent throttling a fetch request
   * - ``kafka.consumer:type=consumer-fetch-manager-metrics,client-id=([-.w]+),name=fetch-throttle-time-max``
     - The maximum time in ms that a broker spent throttling a fetch request


Consumer Lag
~~~~~~~~~~~~

Additionally, it is important to monitor your application’s ``consumer lag``,
which is the number of records for any partition that the consumer is behind in
the log. This metric is particularly important for real-time consumer
applications where the consumer should be processing the newest messages with as
low latency as possible. Monitoring consumer lag can indicate whether the
consumer is able to fetch records fast enough from the brokers. Also consider
how the offsets are committed. For example, exactly-once semantics (EOS) provide
stronger guarantees while potentially increasing consumer lag. You can monitor
consumer lag from the |ccloud| user interface, as described in the `documentation
<https://docs.confluent.io/current/cloud/using/monitor-lag.html>`__.
Alternatively, if you are capturing JMX metrics, you can monitor
``records-lag-max``:

.. list-table::
   :widths: 50 50
   :header-rows: 1
   :class: verticaltable

   * - Metric
     - Description
   * - ``kafka.consumer:type=consumer-fetch-manager-metrics,client-id=([-.w]+),records-lag-max``
     - The maximum lag in terms of number of records for any partition in this
       window. An increasing value over time is your best indication that the
       consumer group is not keeping up with the producers.
