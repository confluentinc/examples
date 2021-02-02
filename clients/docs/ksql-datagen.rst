.. _client-examples-ksql-datagen:

KSQL Datagen: Example for |ak-tm|
=================================

In this tutorial, you will run a KSQL Datagen client application using the `KSQL
Datagen command-line tool
<https://docs.ksqldb.io/en/latest/developer-guide/test-and-debug/generate-custom-test-data/>`__
that produces messages to and consumes messages from an |ak-tm| cluster.

.. note::

    Use KSQL Datagen for development purposes only. It isn't suitable for a
    production environment.

.. include:: includes/client-example-overview.rst



Prerequisites
-------------

Client
~~~~~~

-  Docker

-  `Download <https://www.confluent.io/download/>`__ |cp| |release|

Kafka Cluster
~~~~~~~~~~~~~

.. include:: includes/client-example-prerequisites.rst


Setup
-----

#. .. include:: includes/clients-checkout.rst

#. Change directory to the example for KSQL Datagen.

   .. code-block:: bash

      cd clients/cloud/ksql-datagen/

#. .. include:: includes/client-example-create-file-java.rst


Basic Producer and Consumer
---------------------------

.. include:: includes/producer-consumer-description.rst


Produce Records
~~~~~~~~~~~~~~~

#. Create the |ak| topic.

   .. code-block:: bash

       kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` --command-config $HOME/.confluent/java.config --topic test1 --create --replication-factor 3 --partitions 6

#. Generate a file of ENV variables used by Docker to set the bootstrap
   servers and security configuration.

   .. code-block:: bash

      ../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.confluent/java.config

#. Source the generated file of ``ENV`` variables.

   .. code-block:: bash

      source ./delta_configs/env.delta

#. Start Docker by running the following command:

   .. code-block:: bash

       docker-compose up -d

#. View the :devx-examples:`ksql-datagen code|clients/cloud/ksql-datagen/start-docker.sh`.


Consume Records
~~~~~~~~~~~~~~~

#. Consume from topic ``test1`` by doing the following:

   -  Referencing a properties file

      .. code-block:: bash

         docker-compose exec connect bash -c 'kafka-console-consumer --topic test1 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer.config /tmp/ak-tools-ccloud.delta --max-messages 5'

   -  Referencing individual properties

      .. code-block:: bash

         docker-compose exec connect bash -c 'kafka-console-consumer --topic test1 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer-property sasl.mechanism=PLAIN --consumer-property security.protocol=SASL_SSL --consumer-property sasl.jaas.config="$SASL_JAAS_CONFIG_PROPERTY_FORMAT" --max-messages 5'

   You should see messages similar to the following:

   .. code-block:: text

      {"ordertime":1489322485717,"orderid":15,"itemid":"Item_352","orderunits":9.703502112840228,"address":{"city":"City_48","state":"State_21","zipcode":32731}}

#. When you are done, press ``CTRL-C``.

#. View the :devx-examples:`consumer code|clients/cloud/ksql-datagen/start-docker.sh`.


Avro and Confluent Cloud Schema Registry
----------------------------------------

.. include:: includes/schema-registry-scenario-explain.rst

#. .. include:: includes/client-example-schema-registry-1.rst

#. .. include:: includes/client-example-vpc.rst

#. .. include:: includes/schema-registry-java.rst

#. .. include:: includes/client-example-schema-registry-2-java.rst


Produce Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Create the topic in |ccloud|.

   .. code-block:: bash

       kafka-topics --bootstrap-server `grep "^\s*bootstrap.server" $HOME/.confluent/java.config | tail -1` --command-config $HOME/.confluent/java.config --topic test2 --create --replication-factor 3 --partitions 6

#. Generate a file of ``ENV`` variables used by Docker to set the bootstrap
   servers and security configuration.

   .. code-block:: bash

      ../../../ccloud/ccloud-generate-cp-configs.sh $HOME/.confluent/java.config

#. Source the generated file of ``ENV`` variables.

   .. code-block:: bash

      source ./delta_configs/env.delta

#. Start Docker by running the following command:

   .. code-block:: bash

       docker-compose up -d

#. View the :devx-examples:`ksql-datagen Avro code|clients/cloud/ksql-datagen/start-docker-avro.sh`.


Consume Avro Records
~~~~~~~~~~~~~~~~~~~~

#. Consume from topic ``test2`` by doing the following:

   -  Referencing a properties file

      .. code-block:: bash

         docker-compose exec connect bash -c 'kafka-avro-console-consumer --topic test2 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer.config /tmp/ak-tools-ccloud.delta --property basic.auth.credentials.source=$CONNECT_VALUE_CONVERTER_BASIC_AUTH_CREDENTIALS_SOURCE --property schema.registry.basic.auth.user.info=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property schema.registry.url=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL --max-messages 5'

   -  Referencing individual properties

      .. code-block:: bash

         docker-compose exec connect bash -c 'kafka-avro-console-consumer --topic test2 --bootstrap-server $CONNECT_BOOTSTRAP_SERVERS --consumer-property sasl.mechanism=PLAIN --consumer-property security.protocol=SASL_SSL --consumer-property sasl.jaas.config="$SASL_JAAS_CONFIG_PROPERTY_FORMAT" --property basic.auth.credentials.source=$CONNECT_VALUE_CONVERTER_BASIC_AUTH_CREDENTIALS_SOURCE --property schema.registry.basic.auth.user.info=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO --property schema.registry.url=$CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL --max-messages 5'

   You should see messages similar to the following:

   .. code-block:: text

      {"ordertime":{"long":1494153923330},"orderid":{"int":25},"itemid":{"string":"Item_441"},"orderunits":{"double":0.9910185646928878},"address":{"io.confluent.ksql.avro_schemas.KsqlDataSourceSchema_address":{"city":{"string":"City_61"},"state":{"string":"State_41"},"zipcode":{"long":60468}}}}


#. When you are done, press ``CTRL-C``.

#. View the :devx-examples:`consumer Avro code|clients/cloud/ksql-datagen/start-docker-avro.sh`.


Confluent Cloud Schema Registry
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. View the schema information registered in |sr-ccloud|. In the following
   output, substitute values for ``<SR API KEY>``, ``<SR API SECRET>``, and
   ``<SR ENDPOINT>``.

   .. code-block:: text

       curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects

#. Verify the subject ``test2-value`` exists.

   .. code-block:: text

      ["test2-value"]

#. View the schema information for subject ``test2-value``. In the following
   output, substitute values for ``<SR API KEY>``, ``<SR API SECRET>``, and ``<SR ENDPOINT>``.

   .. code-block:: text

      curl -u <SR API KEY>:<SR API SECRET> https://<SR ENDPOINT>/subjects/test2-value/versions/1

#. Verify the schema information for subject ``test2-value``.

   .. code-block:: text

      {"subject":"test2-value","version":1,"id":100001,"schema":"{\"type\":\"record\",\"name\":\"KsqlDataSourceSchema\",\"namespace\":\"io.confluent.ksql.avro_schemas\",\"fields\":[{\"name\":\"ordertime\",\"type\":[\"null\",\"long\"],\"default\":null},{\"name\":\"orderid\",\"type\":[\"null\",\"int\"],\"default\":null},{\"name\":\"itemid\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"orderunits\",\"type\":[\"null\",\"double\"],\"default\":null},{\"name\":\"address\",\"type\":[\"null\",{\"type\":\"record\",\"name\":\"KsqlDataSourceSchema_address\",\"fields\":[{\"name\":\"city\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"state\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"zipcode\",\"type\":[\"null\",\"long\"],\"default\":null}]}],\"default\":null}]}"}
