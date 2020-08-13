
Create a local file (for example, at ``$HOME/.confluent/springboot.config``) with configuration parameters to connect to your |ak| cluster.
Starting with one of the templates below, customize the file with connection information to your cluster, substituting the parameters in ``{{ }}`` with real values (see :ref:`cloud-config-client` for instructions on how to create or find those values).

- Template configuration file for |ccloud|

  .. literalinclude:: includes/configs/cloud/springboot.config

- Template configuration file for local host

  .. literalinclude:: includes/configs/local/springboot.config
