The Connect worker is backed to the origin on-prem Kafka cluster, so set the replication factor required for the origin onprem cluster:

.. sourcecode:: bash

   replication.factor=<replication-factor-onprem>
   config.storage.replication.factor=<replication-factor-onprem>
   offset.storage.replication.factor=<replication-factor-onprem>
   status.storage.replication.factor=<replication-factor-onprem>

The origin on-prem Kafka cluster can have a varied set of security features enabled, but for simplicity in this example we show no security configurations, just PLAINTEXT.
The Connect worker’s admin client requires connection information to the onprem cluster.

.. sourcecode:: bash
   
   bootstrap.servers=<bootstrap-servers-onprem>

