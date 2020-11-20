Configure SSL trust store
^^^^^^^^^^^^^^^^^^^^^^^^^

Depending on your operating system or Linux distribution you may need to take extra
steps to set up the SSL CA root certificates. If your system doesn't have the
SSL CA root certificates properly set up, you may receive a ``SSL handshake failed``
error message similar to the following:

.. code-block:: bash

   %3|1605776788.619|FAIL|rdkafka#producer-1| [thrd:sasl_ssl://...confluent.cloud:9092/bootstr]: sasl_ssl://...confluent.cloud:9092/bootstrap: SSL handshake failed: error:14090086:SSL routines:ssl3_get_server_certificate:certificate verify failed: broker certificate could not be verified, verify that ssl.ca.location is correctly configured or root CA certificates are installed (brew install openssl) (after 258ms in state CONNECT)

In this case, you need to manually install a bundle of validated CA root certificates and potentially modify the client code to set the ``ssl.ca.location`` configuration property.
(For more information, see the documentation for `librdkafka <https://github.com/edenhill/librdkafka/blob/master/INTRODUCTION.md#ssl>`__ on which this client is built)

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

For the Python client, use ``certifi.where()`` to determine the location of the certificate files:

.. code-block:: text

   ssl.ca.location: certifi.where()

For other clients, check the install path and provide it in the code:

.. code-block:: text

   ssl.ca.location: '/usr/local/etc/openssl@1.1/cert.pem'


CentOS
""""""

You may need to install CA root certificates in the following way:

.. code-block:: bash

   sudo yum reinstall ca-certificates

This should be sufficient for the Kafka clients to find the certificates.
However, if you still get the same error, you can set the ``ssl.ca.location`` property in the client code.
Edit both the producer and consumer code files, and add the ``ssl.ca.location`` configuration parameter into the producer and consumer properties.
The value should correspond to the location of the appropriate CA root certificates file on your host, for example:

.. code-block:: text

   ssl.ca.location: '/etc/ssl/certs/ca-bundle.crt'
