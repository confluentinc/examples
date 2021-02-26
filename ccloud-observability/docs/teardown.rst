.. _ccloud-observability-teardown:

Clean up |ccloud| resources
---------------------------

#. Tear down the Docker monitoring containers:

   .. code-block:: bash

      docker-compose down

#. Delete the cloud api key created for the ``ccloud-exporter``:

   .. code-block:: bash

      ccloud api-key delete $METRICS_API_KEY

#. Run the following to teardown the ccloud-stack, inserting your service account ID instead of ``184498``.
   Your service account ID can be found in your client configuration file (ie ``stack-configs/java-service-account-184498.config``).

   .. code-block:: bash

      source ../utils/ccloud_library.sh
      ccloud::destroy_ccloud_stack 184498
