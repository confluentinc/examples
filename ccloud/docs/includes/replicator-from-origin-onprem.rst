The origin cluster in this case is your on-premises |ak| cluster, and |crep| needs to know how to connect to this origin cluster which can be set by using the prefix ``src.`` for these configuration parameters.
The origin cluster can have a varied set of security features enabled, but for simplicity this example shows no security configurations, just PLAINTEXT.

.. sourcecode:: bash

   src.kafka.bootstrap.servers=<bootstrap-servers-origin>
