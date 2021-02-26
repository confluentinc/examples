.. _ccloud-observability-general-fail-to-create-partition:

Failing to create a new partition
*********************************

It's possible you won't be able to create a partition because you have reached a one of |ccloud|'s partition limits.
Follow the instructions below to check if your cluster is getting close to its partition limits.

#. Open `Grafana <localhost:3000>`__ and use the username ``admin`` and password ``password`` to login.

#. Navigate to the ``Confluent Cloud`` dashboard.

#. Check the ``Partition Count`` panel. If this panel is yellow, you have used 80% of your allowed partitions; if it's red, you have used 90%.

   |Confluent Cloud Panel|

   A maximum number of partitions can exist on the cluster at one time, before replication.
   All topics that are created by you as well as internal topics that are automatically created by
   Confluent Platform components–such as ksqlDB, Kafka Streams, Connect, and Control Center–count towards the cluster partition limit.

#. Check the ``Partition count change (delta)`` panel. |ccloud| clusters have a limit on the
   number of partitions that can be created and deleted in a 5 minute period. This single stat
   provides the absolute difference between the number of partitions at the beginning and end of
   the 5 minute period. This over simplifies the problem. An example being, at the start of a 5
   minute window you have 18 partitions. During the 5 minute window you create a new topic with 6
   partitions and delete a topic with 6 partitions. At the end of the five minute window you still
   have 18 partitions but you actually created and deleted 12 partitions.

   More conservative thresholds are put in place--this panel will turn yellow when at 50%
   utilization and red at 60%.

.. |Confluent Cloud Panel|
   image:: ../images/cloud-panel.png
   :alt: Confluent Cloud Panel