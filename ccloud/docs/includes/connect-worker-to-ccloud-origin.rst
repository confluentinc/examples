The connect worker is backed to the origin |ccloud| cluster.
All these bootstrap server values and API key credentials refer to the origin cluster, not the destination cluster.

   .. literalinclude:: ../template_delta_configs/connect-ccloud.delta
      :lines: 1-35

There is one additional required configuration parameter for the connect worker that is required when the worker is backed to the origin cluster instead of the destination cluster, which allows the connectors (|crep| in this case) to override some configurations.

   .. sourcecode:: bash

      connector.client.config.override.policy=all

