.. _ccloud-monitoring-consumer-connectivity-problem:

Consumer Lag Problem
********************

Consumer group lag is a tremendous performance indicator. It informs you how far behind the latest offset
a consumer group is, essentially the difference between the producer's last produced messaeg and
the consumer group's latest commit. `kafka-lag-exporter <https://github.com/lightbend/kafka-lag-exporter>`__
is an open source project that collects consumer group lag information and presents it in a Prometheus
scrapable format. A large or quickly growing lag indicates that the consumer is not able to keep up with
the volume of messages on a topic.

Introduce failure scenario
^^^^^^^^^^^^^^^^^^^^^^^^^^

#. Stop ``consumer-1`` container, thus removing a consumer from the consumer group and add 2 producers:

   .. code-block:: bash

      docker-compose up -d --scale consumer=1 --scale producer=5

   Which will produce the following output:

   .. code-block:: bash

      ccloud-exporter is up-to-date
      kafka-lag-exporter is up-to-date
      node-exporter is up-to-date
      grafana is up-to-date
      prometheus is up-to-date
      Stopping and removing ccloud-monitoring_consumer_2 ... done
      Starting ccloud-monitoring_producer_1              ... done
      Creating ccloud-monitoring_producer_2              ... done
      Creating ccloud-monitoring_producer_3              ... done
      Creating ccloud-monitoring_producer_4              ... done
      Creating ccloud-monitoring_producer_5              ... done
      Starting ccloud-monitoring_consumer_1              ... done

Diagnose the problem
^^^^^^^^^^^^^^^^^^^^

#. Open `Grafana <localhost:3000>`__ and login with the username ``admin`` and password ``password``.

#. Navigate to the ``Consumer Client Metrics`` dashboard.

   - Within a minute you should see an upward trend in ``Consumer group lag`` both by seconds and by offsets.

   - The rebalance rate should have a bump, indicating that the consumer group <insert cg name> underwent a rebalance, which is to be expected when a consumer leaves the group.

   - Within two minutes you should notice an increase in ``Fetch request rate``.

   - After two minutes, you will notice all of the graphs in the ``Throughput`` are indicating the consume is processing more bytes/records.



Resolve failure scenario
^^^^^^^^^^^^^^^^^^^^^^^^

#. Start ``consumer-1`` container, thus adding a consumer back to the consumer group, and stop the extra producers:

   .. code-block:: bash

      docker-compose up -d --scale consumer=2 --scale producer=1

   Which will produce the following output:

   .. code-block:: bash

      node-exporter is up-to-date
      grafana is up-to-date
      kafka-lag-exporter is up-to-date
      prometheus is up-to-date
      ccloud-exporter is up-to-date
      Stopping and removing ccloud-monitoring_producer_2 ... done
      Stopping and removing ccloud-monitoring_producer_3 ... done
      Stopping and removing ccloud-monitoring_producer_4 ... done
      Stopping and removing ccloud-monitoring_producer_5 ... done
      Starting ccloud-monitoring_consumer_1              ... done
      Creating ccloud-monitoring_consumer_2              ... done
      Starting ccloud-monitoring_producer_1              ... done

