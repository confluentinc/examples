Add the following parameters to your local |ccloud| configuration
file. In the output below, substitute values for ``{{SR_API_KEY }}``, ``{{
SR_API_SECRET }}``, and ``{{ SR_ENDPOINT }}``.

.. code-block:: text

   $ cat $HOME/.confluent/java.config
   ...
   basic.auth.credentials.source=USER_INFO
   schema.registry.basic.auth.user.info={{ SR_API_KEY }}:{{ SR_API_SECRET }}
   schema.registry.url=https://{{ SR_ENDPOINT }}
   ...
