Since the |kconnect| workers are backed to the origin cluster, its embedded producers would write to the origin cluster, which is not desired in this case.
To override the embedded producers, configure |crep| to write to the destination |ccloud| cluster by adding connection information to |ccloud| with the prefix ``producer.override.``:

.. sourcecode:: bash

   producer.override.bootstrap.servers=<bootstrap-servers-destination>
   producer.override.security.protocol=SASL_SSL
   producer.override.sasl.mechanism=PLAIN
   producer.override.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="<api-key-destination>" password="<api-secret-destination>";
