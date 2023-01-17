.. _ccloud-observability-teardown:

Clean up |ccloud| resources
---------------------------

Run the ``./stop.sh`` script, passing the path to your stack configuration as an argument. Insert your service account ID instead of ``sa-123456`` in the example below.
Your service account ID can be found in your client configuration file path (i.e., ``stack-configs/java-service-account-sa-123456.config``).

The ``METRICS_API_KEY`` environment variable must be set when you run this script in order to delete the Metrics API key that ``start.sh`` created for Prometheus to
be able to scrape the Metrics API. The key was output at the end of the ``start.sh`` script, or you can find it in the ``.env`` file
that ``start.sh`` created.

   .. code-block:: bash

      METRICS_API_KEY=XXXXXXXXXXXXXXXX ./stop.sh stack-configs/java-service-account-sa-123456.config

You will see output like the following once all local containers and Confluent Cloud resources have been cleaned up:

   .. code-block:: bash

      Deleted API key "XXXXXXXXXXXXXXXX".
      [+] Running 7/7
       ⠿ Container kafka-lag-exporter               Removed                                                         0.6s
       ⠿ Container grafana                          Removed                                                         0.5s
       ⠿ Container prometheus                       Removed                                                         0.5s
       ⠿ Container node-exporter                    Removed                                                         0.4s
       ⠿ Container ccloud-observability-consumer-1  Removed                                                         0.6s
       ⠿ Container ccloud-observability-producer-1  Removed                                                         0.6s
       ⠿ Network ccloud-observability_default       Removed                                                         0.1s
      This script will destroy all resources in java-service-account-sa-123456.config.  Do you want to proceed? [y/n] y
      Now using "env-123456" as the default (active) environment.
      Destroying Confluent Cloud stack associated to service account id sa-123456
      Deleting CLUSTER: demo-kafka-cluster-sa-123456 : lkc-123456
      Deleted Kafka cluster "lkc-123456".
      Deleted API key "XXXXXXXXXXXXXXXX".
      Deleted service account "sa-123456".
      Deleting ENVIRONMENT: prefix ccloud-stack-sa-123456 : env-123456
      Deleted environment "env-123456".
