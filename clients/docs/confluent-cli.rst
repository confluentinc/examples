.. _client-examples-confluent-cli:

Confluent CLI
--------------

In this tutorial, you will run a Confluent Cloud CLI client application that produces
messages to and consumes messages from an |ak-tm| cluster.

.. include:: includes/client-example-overview.rst

.. note::

   The Confluent CLI is meant for development purposes only and isn't suitable
   for a production environment.

Prerequisites
-------------

Client
~~~~~~

-  `Confluent Platform
   5.5 <https://www.confluent.io/download/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__,
   which includes the Confluent CLI

-  Create a local file (e.g. at ``$HOME/.confluent/java.config``) with
   configuration parameters to connect to your Kafka cluster, which can
   be on your local host, `Confluent
   Cloud <https://www.confluent.io/confluent-cloud/?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__,
   or any other cluster. Follow `these detailed
   instructions <https://github.com/confluentinc/configuration-templates/tree/master/README.md>`__
   to properly create this file.


Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. Clone the `confluentinc/examples GitHub repository
   <https://github.com/confluentinc/examples>`__ and check out the
   :litwithvars:`|release|-post` branch.

   .. codewithvars:: bash

      git clone https://github.com/confluentinc/examples
      cd examples
      git checkout |release|-post

#. Change directory to the example for Confluent CLI.

   .. code-block:: bash

      cd clients/cloud/confluent-cli/

#. .. include:: includes/client-example-create-file.rst


Basic Producer and Consumer
----------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

.. Should steps 1 below be under this  "Produce Records" section or before it?

#. Create the topic in Confluent Cloud

   .. code-block:: bash

      kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` --command-config $HOME/.confluent/java.config --topic test1 --create --replication-factor 3 --partitions 6

#. Run the `Confluent CLI
   producer <https://docs.confluent.io/current/cli/command-reference/confluent-produce.html#cli-confluent-produce?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__,
   writing messages to topic ``test1``, passing in arguments for:

   -  ``--cloud``: write messages to the Confluent Cloud cluster specified in
      ``$HOME/.confluent/java.config``
   -  ``--property parse.key=true --property key.separator=,``: pass key and
      value, separated by a comma

   .. code-block:: bash

      confluent local produce test1 -- --cloud --property parse.key=true --property key.separator=,

#. At the ``>`` prompt, type a few messages, using a ``,`` as the separator
   between the message key and value:

   .. code-block:: bash

       alice,{"count":0}
       alice,{"count":1}
       alice,{"count":2}

#. When you are done, press ``Ctrl-D``.

.. source code for producer?

Consume Records
~~~~~~~~~~~~~~~

#. Run the `Confluent CLI
   consumer
   <https://docs.confluent.io/current/cli/command-reference/confluent-consume.html#cli-confluent-consume?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__,
   reading messages from topic ``test1``, passing in additional arguments:

   -  ``--cloud``: read messages from the Confluent Cloud cluster specified in
      ``$HOME/.confluent/java.config``
   -  ``--property print.key=true``: print key and value (by default, it only
      prints value)
   -  ``--from-beginning``: print all messages from the beginning of the topic

   .. code-block:: bash

      confluent local consume test1 -- --cloud --property print.key=true --from-beginning

You should see the messages you typed in the previous step.
.. Is "previous step" is referring to step 3 in the "Produce Records" section?

.. code-block:: bash

   alice   {"count":0}
   alice   {"count":1}
   alice   {"count":2}

When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`consumer code|clients/cloud/java/src/main/java/io/confluent/examples/clients/cloud/confluent-cli/confluent-cli-example.sh`.


Avro And Confluent Cloud Schema Registry
----------------------------------------

.. include:: includes/client-example-schema-registry-3.rst

.. Do we want to create a separate section, for steps 1 through 5, leave them as is
   or put them under the "Produce Records" section?

#. As described in the `Confluent Cloud
   quickstart <https://docs.confluent.io/current/quickstart/cloud-quickstart/schema-registry.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__,
   in the Confluent Cloud GUI, enable Confluent Cloud Schema Registry
   and create an API key and secret to connect to it.

#. Verify your Confluent Cloud Schema Registry credentials work from
   your host. In the output below, substitute your values for
   ``<SR API KEY>``, ``<SR API SECRET>``, and ``<SR ENDPOINT>``.

   .. code-block:: text

      # View the list of registered subjects
      curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects

      # Same as above, as a single bash command to parse the values out of $HOME/.confluent/java.config
      curl -u $(grep "^schema.registry.basic.auth.user.info" $HOME/.confluent/java.config | cut -d'=' -f2) $(grep "^schema.registry.url" $HOME/.confluent/java.config | cut -d'=' -f2)/subjects

#. View your local Confluent Cloud configuration file (``$HOME/.confluent/java.config``):

   .. code-block:: bash

      cat $HOME/.confluent/java.config

#. In the configuration file, substitute values for ``<SR API KEY>``,
   ``<SR API SECRET>``, and ``<SR ENDPOINT>``  as displayed in the following
   example:

   .. code-block:: bash

      ...
      basic.auth.credentials.source=USER_INFO
      schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
      schema.registry.url=https://<SR ENDPOINT>
      ...

#. Create the topic in Confluent Cloud.

   .. code-block:: bash

      kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` --command-config $HOME/.confluent/java.config --topic test2 --create --replication-factor 3 --partitions 6


Produce Records
~~~~~~~~~~~~~~~

#. Run the `Confluent CLI
   producer <https://docs.confluent.io/current/cli/command-reference/confluent-produce.html#cli-confluent-produce?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__,
   writing messages to topic ``test2``, passing in arguments for:

   -  ``--value-format avro``: use Avro data format for the value part of the
      message
   -  ``--property value.schema``: define the schema
   -  ``--property schema.registry.url``: connect to the Confluent Cloud Schema
      Registry endpoint http://

.. In the above list item it says "endpoint http://"
   Is there something missing ?

   -  ``--property basic.auth.credentials.source``: specify ``USER_INFO``
   -  ``--property schema.registry.basic.auth.user.info``

   .. important::

      The additional Schema Registry parameters are required to be passed
      in as properties instead of a properties file due to
      https://github.com/confluentinc/schema-registry/issues/1052.

   .. code-block:: bash

      confluent local produce test2 -- --cloud --value-format avro --property value.schema='{"type":"record","name":"myrecord","fields":[{"name":"count","type":"int"}]}' --property schema.registry.url=https://<SR ENDPOINT> --property basic.auth.credentials.source=USER_INFO --property schema.registry.basic.auth.user.info='<SR API KEY>:<SR API SECRET>'

#. At the ``>`` prompt, type the following messages:

   .. code-block:: bash

      {"count":0}
      {"count":1}
      {"count":2}

#. When you are done, press ``Ctrl-D``.

.. source code for Avro producer?

Consume Records
~~~~~~~~~~~~~~~

#. Run the `Confluent CLI
   consumer <https://docs.confluent.io/current/cli/command-reference/confluent-consume.html#cli-confluent-consume?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud>`__,
   reading messages from topic ``test``, passing in additional
   arguments. The additional Schema Registry parameters are required to
   be passed in as properties instead of a properties file due to
   https://github.com/confluentinc/schema-registry/issues/1052.

-  ``--value-format avro``: use Avro data format for the value part of
   the message
-  ``--property schema.registry.url``: connect to the Confluent Cloud
   Schema Registry endpoint http://
-  ``--property basic.auth.credentials.source``: specify ``USER_INFO``
-  ``--property schema.registry.basic.auth.user.info``: :

.. code-block:: bash

    confluent local consume test2 -- --cloud --value-format avro --property schema.registry.url=https://<SR ENDPOINT> --property basic.auth.credentials.source=USER_INFO --property schema.registry.basic.auth.user.info='<SR API KEY>:<SR API SECRET>' --from-beginning

You should see the messages you typed in the previous step.

.. code-block:: bash

   {"count":0}
   {"count":1}
   {"count":2}

#. When you are done, press ``Ctrl-C``.

#. View the :devx-examples:`consumer code|clients/cloud/java/src/main/java/io/confluent/examples/clients/cloud/confluent-cli/confluent-cli-ccsr-example.sh`.

