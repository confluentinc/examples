Finally, configure the Connect worker to allow overrides, because |crep| needs to override the default behavior of the Connect worker's embedded producer.

.. sourcecode:: bash

   connector.client.config.override.policy=all

