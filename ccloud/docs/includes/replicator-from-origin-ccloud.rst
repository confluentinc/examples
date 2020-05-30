The origin cluster in this case is a |ccloud| cluster, and |crep| needs to know how to connect to this origin cluster which can be set by using the prefix ``src.`` for these configuration parameters.

   .. sourcecode:: bash

      src.kafka.bootstrap.servers=<origin Confluent Cloud bootstrap server>
      src.ssl.endpoint.identification.algorithm=https
      src.kafka.security.protocol=SASL_SSL
      src.kafka.sasl.mechanism=PLAIN
      src.kafka.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="<CCLOUD_API_KEY>" password="<CCLOUD_API_SECRET>";

