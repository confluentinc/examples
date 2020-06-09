Finally, configure the |kconnect| worker to allow overrides, because |crep| needs to override the default behavior of the |kconnect| worker's embedded producer.

.. sourcecode:: bash

   connector.client.config.override.policy=All
