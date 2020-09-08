Troubleshooting
---------------

- If you observe that the replicated offsets do not match in the source and destination cluster, the destination cluster may have existed prior to starting the cluster in situations where you may have restarted the demonstration.  To see the full demonstration function properly, use a new cluster or delete and recreate the destination topic prior to running the demo.

Suggested Reading
-----------------

- Blog post: `Conquering Hybrid Cloud with Replicated Event-Driven Architectures <https://www.confluent.io/blog/replicated-event-driven-architectures-for-hybrid-cloud-kafka/>`__
