
Create a local file (for example, at ``$HOME/.confluent/librdkafka.config``) with configuration parameters to connect to your |ak| cluster.
You can use one of the templates below and customize the file with connection information to your |ak| cluster, substitute the parameters with real values (:ref:`Here <cloud-config-client>` is how to create or find those values):

- Template configuration file for |ccloud|

  .. literalinclude:: includes/configs/cloud/librdkafka.config

- Template configuration file for local host

  .. literalinclude:: includes/configs/local/librdkafka.config
