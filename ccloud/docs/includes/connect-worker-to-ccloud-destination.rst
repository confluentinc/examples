The connect workers in the connect clusters should be configured as shown in this :devx-examples:`connect worker delta configuration file|ccloud/template_delta_configs/connect-ccloud.delta`.

   .. literalinclude:: ../template_delta_configs/connect-ccloud.delta
      :lines: 1-35

Notice a few things:

#. The connect cluster's admin topics must be set to replication factor of 3 as required by |ccloud|.

#. The connect worker's admin client requires |ccloud| connection information.

#. The connect worker's embedded producer and embedded consumer require |ccloud| connection information.

#. If you are using |c3| and doing stream monitoring then the embedded producer and consumer's monitoring interceptors require |ccloud| connection information.

