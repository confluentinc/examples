Set the management topics to replication factor of 3 as required by |ccloud|.

.. literalinclude:: config/connect-ccloud-origin.delta
   :lines: 1-4

The Connect worker's admin client requires connection information to the origin |ccloud|.

.. literalinclude:: config/connect-ccloud-origin.delta
   :lines: 6-11

The Connect worker's embedded producer and embedded consumer require connection information to the origin |ccloud|.

.. literalinclude:: config/connect-ccloud-origin.delta
   :lines: 13-23

If you are using |c3| and doing stream monitoring then the embedded producer and consumer's monitoring interceptors require connection information to the origin |ccloud|.

.. literalinclude:: config/connect-ccloud-origin.delta
   :lines: 25-35

