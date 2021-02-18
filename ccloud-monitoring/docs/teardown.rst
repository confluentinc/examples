.. _ccloud-monitoring-teardown:

Clean up |ccloud| resources
----------------------------------

#. Tear down monitoring containers by entering the following into the CLI:

   .. code-block:: bash

      docker-compose down

#. Run the following to teardown the ccloud-stack:
   .. code-block:: bash

      source ../utils/ccloud_library.sh
      ccloud::ccloud_stack_destroy stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config

In this case, run the following script to delete the example’s topics, |ak|
cluster, and environment:

.. code-block:: bash

   ./cleanup.sh
