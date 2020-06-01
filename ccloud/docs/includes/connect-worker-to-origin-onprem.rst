The |kconnect| worker is backed to the origin on-premises |ak| cluster, so set the replication factor required for the origin on-premises cluster:

.. sourcecode:: bash

   replication.factor=<replication-factor-origin>
   config.storage.replication.factor=<replication-factor-origin>
   offset.storage.replication.factor=<replication-factor-origin>
   status.storage.replication.factor=<replication-factor-origin>

The origin on-premises |ak| cluster can have a varied set of security features enabled, but for simplicity in this example we show no security configurations, just PLAINTEXT.
The |kconnect| worker’s admin client requires connection information to the on-premises cluster.

.. sourcecode:: bash
   
   bootstrap.servers=<bootstrap-servers-origin>
