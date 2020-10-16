Verify |c3-short|'s View of Multiple Clusters
+++++++++++++++++++++++++++++++++++++++++++++++++

.. include:: ../../docs/includes/port-forward-c3.rst

Now open a web-browser to http://localhost:12345, and you should see |c3| with 2 Healthy Clusters.  

.. figure:: images/c3-dual-clusters.png
    :alt: c3

The replicator-|operator-demo-prefix|-cc-demo cluster is the |ccloud| cluster and the ``controlcenter.cluster`` is the |k8s-service-name| based |co-long| managed cluster.  At this time, detailed monitoring of |ccloud| clusters is not possible from on-premises |c3|.  You will notice that the replicator-|operator-demo-prefix|-cc-demo cluster does not list the number of Brokers as the `Confluent Cloud managed Kafka service is serverless <https://www.confluent.io/blog/kafka-made-serverless-with-confluent-cloud>`__ and the concept of brokers is abstracted away.

Next click on the ``controlcenter.cluster`` and then ``Consumers``, and then ``replicator``.  This will give you a view of the |crep-full| consumer group as it replicates the ``stock-trades`` topics to |ccloud|.

.. figure:: ../../docs/images/replicator-consumer.png
    :alt: c3-replicator-consumer

This |c3-short| screen highlights the consumer group lag for the ``replicator`` consumer group.  In the above screenshot, |c3-short| is telling us that the ``replicator`` consumer's total lag across all topics and partitions is 27 messages.  As |crep| processes messages, it's consumer group lag will fluctuate and the chart on this screen will indicate the current value as well as maximum amount of lag over time.

Verify replicated stock-trades topic with clients
+++++++++++++++++++++++++++++++++++++++++++++++++

To view the ``stock-trades`` topic data streaming on both clusters, you can open two terminals and run the following series of commands.

#.  To view the ``stock-trades`` events on the source (|k8s-service-name|) cluster, in the first terminal, first open a shell on the ``client-console`` pod:

    ::

        kubectl -n operator exec -it client-console bash

#.  Then use the ``kafka-console-consumer`` to stream the values from the ``stock-trades`` topic.  The required configuraiton is provided in the ``/etc/kafka-client-properties/kafka-client.properties`` file already mounted in a volume on the pod:

    ::

        kafka-console-consumer --bootstrap-server kafka:9071 --consumer.config /etc/kafka-client-properties/kafka-client.properties --topic stock-trades --property print.value=false --property print.key=true --property print.timestamp=true

#.  To view the ``stock-trades`` events on the destination (Confluent Cloud) cluster, in a second terminal open another shell on the ``client-console`` pod:

    ::

        kubectl -n operator exec -it client-console bash

#.  Again, use the ``kafka-console-consumer`` to stream the values from the ``stock-trades`` topic, this time from the destination cluster.   The required configuration has been mounted in a volume on the pod in the ``/etc/destination-cluster-client-properties/destination-cluster-client.properties`` file.   Additionally, the bootstrap server value has been added in the ``/etc/destination-cluster-client-properties/destination-cluster-bootstrap`` file.  This command will use both of those files to create the connection to the destination cluster:

    ::

        kafka-console-consumer --bootstrap-server $(cat /etc/destination-cluster-client-properties/destination-cluster-bootstrap)  --consumer.config /etc/destination-cluster-client-properties/destination-cluster-client.properties --topic stock-trades --property print.value=false --property print.key=true --property print.timestamp=true

    These commands will print out the timestamp and key of messages as they arrive in each cluster.  You an visually match up the events by these values and observe the replication process, for example, in terminal 1 you might see:

    ::

        ...
        CreateTime:1572380698171        ZJZZT
        CreateTime:1572380698280        ZWZZT
        CreateTime:1572380698351        ZWZZT
        CreateTime:1572380698577        ZJZZT
        CreateTime:1572380699340        ZVZZT

    And in terminal 2 shortly after identical messages:

    ::

        ...
        CreateTime:1572380698171        ZJZZT
        CreateTime:1572380698280        ZWZZT
        CreateTime:1572380698351        ZWZZT
