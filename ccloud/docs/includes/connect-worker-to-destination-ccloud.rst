The connect workers in the connect clusters should be configured to connect to |ccloud|.

#. The connect cluster's admin topics must be set to replication factor of 3 as required by |ccloud|.

   .. literalinclude:: ../config/connect-ccloud-destination.delta
      :lines: 1-4

#. The connect worker's admin client requires connection information to the destination |ccloud|.

   .. literalinclude:: ../config/connect-ccloud-destination.delta
      :lines: 7-11

#. The connect worker's embedded producer and embedded consumer require connection information to the destination |ccloud|.

   .. literalinclude:: ../config/connect-ccloud-destination.delta
      :lines: 13-23

#. If you are using |c3| and doing stream monitoring then the embedded producer and consumer's monitoring interceptors require connection information to the destination |ccloud|.

   .. literalinclude:: ../config/connect-ccloud-destination.delta
      :lines: 25-35

