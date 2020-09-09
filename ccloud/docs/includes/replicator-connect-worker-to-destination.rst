The destination cluster is your |ccloud| cluster, and |crep| needs to know how to connect to it.
Use the prefix ``dest.`` to set these configuration parameters.

.. sourcecode:: bash

   # Confluent Replicator license topic must have replication factor set to 3 for |ccloud|
   confluent.topic.replication.factor=3

   # New user topics that |crep-full| creates must have replication factor set to 3 for |ccloud| 
   dest.topic.replication.factor=3

If your deployment has |c3| end-to-end streams monitoring setup to gather data in |ccloud|, then you also need to setup the Confluent Monitoring Interceptors to send data to your |ccloud| cluster, which also requires appropriate connection information set for the embedded consumer with the prefix ``src.consumer``.

.. sourcecode:: bash

   src.consumer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor
   src.consumer.confluent.monitoring.interceptor.bootstrap.servers=<bootstrap-servers-destination>
   src.consumer.confluent.monitoring.interceptor.security.protocol=SASL_SSL
   src.consumer.confluent.monitoring.interceptor.sasl.mechanism=PLAIN
   src.consumer.confluent.monitoring.interceptor.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="<api-key-destination>" password="<api-secret-destination>";
