Verify your |ccloud| |sr| credentials work from your host.
In the following example, substitute your values for ``{{ SR_API_KEY}}``,
``{{SR_API_SECRET }}``, and ``{{ SR_ENDPOINT }}``.

.. code-block:: text

   # View the list of registered subjects
   $ curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects

   # Same as above, as a single bash command to parse the values out of  $HOME/.confluent/springboot.config
   $ curl -u $(grep "^schema.registry.basic.auth.user.info"  $HOME/.confluent/springboot.config | cut -d'=' -f2) $(grep "^schema.registry.url"  $HOME/.confluent/springboot.config | cut -d'=' -f2)/subjects
