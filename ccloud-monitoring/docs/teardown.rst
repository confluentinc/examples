.. _ccloud-cli-tutorial-teardown:

Clean up Confluent Cloud resources
----------------------------------

#. Tear down monitoring containers by typing ``docker-compose down`` into the CLI.

#. Complete the following steps to delete the managed connector:

   a. Find the connector ID:

      .. code-block:: bash

         ccloud connector list

      Which should display a something similar to below. Locate your connector ID, in this case the connector ID is ``lcc-zno83``.

      .. code-block:: text

              ID     |           Name           | Status  |  Type  | Trace
         +-----------+--------------------------+---------+--------+-------+
           lcc-zno83 | datagen_ccloud_pageviews | RUNNING | source |


   b. Delete the connector, referencing the connector ID from the previous step:

      .. code-block:: bash

	 ccloud connector delete lcc-zno83

      You should see: ``Deleted connector "lcc-zno83".``.

#. Run the following command to delete the service account:

   .. code-block:: bash

      ccloud service-account delete 104349

#. Complete the following steps to delete all the |ak| topics:

   a. Delete ``demo-topic-1``:

      .. code-block:: bash

         ccloud kafka topic delete demo-topic-1

      You should see: ``Deleted topic "demo-topic-1"``.

   b. Delete ``demo-topic-2``:

      .. code-block:: bash

         ccloud kafka topic delete demo-topic-2

      You should see: ``Deleted topic "demo-topic-2"``.

   c. Delete ``demo-topic-3``:

      .. code-block:: bash

         ccloud kafka topic delete demo-topic-3

      You should see: ``Deleted topic "demo-topic-3"``.

#. Run the following commands to delete the API keys:

   .. code-block:: bash

      ccloud api-key delete ESN5FSNDHOFFSUEV
      ccloud api-key delete QX7X4VA4DFJTTOIA

#. Delete the |ak| cluster:

   .. code-block:: bash

      ccloud kafka cluster delete lkc-x6m01

#. Delete the environment:

   .. code-block:: bash

      ccloud environment delete env-5qz2q

   You should see: ``Deleted environment "env-5qz2q"``.

If the tutorial ends prematurely, you may receive the following error message
when trying to run the example again (``ccloud environment create
ccloud-stack-000000-beginner-cli``):

.. code-block:: text

      Error: 1 error occurred:
         * error creating account: Account name is already in use

      Failed to create environment ccloud-stack-000000-beginner-cli. Please troubleshoot and run again

In this case, run the following script to delete the example’s topics, |ak|
cluster, and environment:

.. code-block:: bash

   ./cleanup.sh
