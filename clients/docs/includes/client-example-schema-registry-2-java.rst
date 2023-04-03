Verify your |ccloud| |sr| credentials by listing the |sr| subjects.
In the following example, substitute your values for ``{{ SR_API_KEY }}``,
``{{ SR_API_SECRET }}``, and ``{{ SR_ENDPOINT }}``.

.. code-block:: text

   curl -u {{ SR_API_KEY }}:{{ SR_API_SECRET }} https://{{ SR_ENDPOINT }}/subjects
