.. _ccloud-monitoring-consumer-connectivity-problem:

Connectivity Problem
********************

In the ``consumer`` container ...

Introduce failure scenario
^^^^^^^^^^^^^^^^^^^^^^^^^^

#. Stop ``consumer-1`` container, thus removing a consumer from the consumer group and add 2 producers:

   .. code-block:: bash

      docker-compose stop consumer-1
      docker-compose start producer-2 producer-3

Diagnose the problem
^^^^^^^^^^^^^^^^^^^^

#. Open `Grafana <localhost:3000>`__ and login with the username ``admin`` and password ``password``.

#. Navigate to the ``Consumer Client Metrics`` dashboard. Within a minute you should see a downward
   trend in incoming bytes which can be found by the expanding the ``Throughput`` tab.

Resolve failure scenario
^^^^^^^^^^^^^^^^^^^^^^^^

#. Start ``consumer-1`` container, thus adding a consumer back to the consumer group, and stop the extra producers:

   .. code-block:: bash

      docker-compose start consumer-1
      docker-compose stop producer-2 producer-3

Troubleshooting
^^^^^^^^^^^^^^^
