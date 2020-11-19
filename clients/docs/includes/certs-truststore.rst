Configure SSL trust store
^^^^^^^^^^^^^^^^^^^^^^^^^

Depending on your operating system or Linux distro you may need to take extra
steps to set up the SSL CA root certificates. If your system doesn't have the
SSL CA root certificates properly set up, you may receive an error message
similar to the following:

.. code-block:: bash

   %3|1554125834.196|FAIL|rdkafka#producer-2| [thrd:sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/boot]: sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/bootstrap: Failed
   %3|1554125834.197|ERROR|rdkafka#producer-2| [thrd:sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/boot]: sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/bootstrap: Faile
   %3|1554125834.197|ERROR|rdkafka#producer-2| [thrd:sasl_ssl://pkc-epgnk.us-central1.gcp.confluent.cloud\:9092/boot]: 1/1 brokers are down

In this case, you need to manually install a bundle of validated CA root certificates before running the client code.
(For more information, see the documentation for `librdkafka <https://github.com/edenhill/librdkafka/wiki/Using-SSL-with-librdkafka>`__ on which this client is built)

macOS
"""""

On newer versions of macOS (for example, 10.15), you may need to add an
additional dependency.

For the Python client:

.. code-block:: bash

   pip install certifi

For other clients:

.. code-block:: bash

   brew install openssl

Once you install the CA root certificates, set the ``ssl.ca.location`` property in the client code.
Edit both the producer and consumer code files, and add the ``ssl.ca.location`` configuration parameter into the producer and consumer properties.
The value should correspond to the location of the appropriate CA root certificates file on your host.

For the Python client, it may be:

.. code-block:: text

   ssl.ca.location: '/Library/Python/3.7/site-packages/certifi/cacert.pem'

For other clients:

.. code-block:: text

   ssl.ca.location: '/usr/local/etc/openssl@1.1/cert.pem'


CentOS
""""""

You may need to install CA root certificates in the following way:

.. code-block:: bash

   sudo yum reinstall ca-certificates

Once you install the CA root certificates, set the ``ssl.ca.location`` property in the client code.
Edit both the producer and consumer code files, and add the ``ssl.ca.location`` configuration parameter into the producer and consumer properties.
The value should correspond to the location of the appropriate CA root certificates file on your host.

.. code-block:: text

   ssl.ca.location: '/etc/ssl/certs/ca-bundle.crt'
