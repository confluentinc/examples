Set the management topics to replication factor of 3 as required by |ccloud|.

.. literalinclude:: config/connect-ccloud-destination.delta
   :lines: 1-4

The |kconnect| worker's admin client requires connection information to the destination |ccloud|.

.. literalinclude:: config/connect-ccloud-destination.delta
   :lines: 6-11

The |kconnect| worker's embedded producer requires connection information to the destination |ccloud|.

.. literalinclude:: config/connect-ccloud-destination.delta
   :lines: 14-17

If you are using |c3| and doing stream monitoring then the embedded producer's monitoring interceptors require connection information to the destination |ccloud|.

.. literalinclude:: config/connect-ccloud-destination.delta
   :lines: 26-29
