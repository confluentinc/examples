.. _ccloud-observability-consumer-overview:

Consumer Client Scenarios
~~~~~~~~~~~~~~~~~~~~~~~~~
The dashboard and scenarios in this section use client metrics from a Java consumer. The same principles can be applied to any
other non-java clients--they generally offer similar metrics.

The source code for the client can found in the
devx-examples:`ccloud-observability/src|ccloud-observability/src` directory. The client
uses default configurations, this is not recommended for production use cases. This Java consumer
will continue to consumer the same message until the process is interrupted. The content of the
message is not important here, in these scenarios the focus is on the change in client metric values.

|Consumer Dashboard|


.. |Consumer Dashboard|
   image:: ../images/consumer-dashboard.png
   :alt: Consumer Dashboard
