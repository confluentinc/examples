Since the connect workers are backed to the origin cluster, by default |crep| would produce data to the origin cluster.
To override this default behavior, you need to configure |crep| to produce data to the destination |ccloud| cluster, by adding configuration parameters with the prefix ``producer.override.``:

.. sourcecode:: bash

   producer.override.bootstrap.servers=<bootstrap-servers-destination>
   producer.override.ssl.endpoint.identification.algorithm=https
   producer.override.security.protocol=SASL_SSL
   producer.override.sasl.mechanism=PLAIN
   producer.override.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="<api-key-destination>" password="<api-secret-destination>";

