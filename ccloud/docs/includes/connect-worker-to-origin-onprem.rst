The connect worker is backed to the origin on-prem Kafka cluster, which can have a varied set of security features enabled, but for simplicity in this example we show no features, just PLAINTEXT.

.. sourcecode:: bash

   # Configuration for embedded admin client
   replication.factor=<replication factor>
   config.storage.replication.factor=<replication factor>
   offset.storage.replication.factor=<replication factor>
   status.storage.replication.factor=<replication factor>
   
   bootstrap.servers=<<bootstrap servers for on-prem>
   
   # Configuration for embedded producer using the prefix 'producer.'
   
   # Configuration for embedded consumer using the prefix 'consumer.'
   
   # Configuration for embedded producer's Confluent Monitoring Interceptors using the prefix 'producer.confluent.monitoring.interceptor.'
   
   # Configuration for embedded consumer's Confluent Monitoring Interceptors using the prefix 'consumer.confluent.monitoring.interceptor.'
