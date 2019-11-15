Deploying Custom Kafka Connect JARs with Operator 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`Kafka Connect <https://docs.confluent.io/current/connect/index.html>`__ employs an extensible programming model to faciliate `Data Conversions <https://docs.confluent.io/current/connect/concepts.html#converters>`__, `Single Message Transformations (SMTs) <https://docs.confluent.io/current/connect/concepts.html#transforms>`__, or the development of custom connectors if a `supported connector <https://www.confluent.io/hub/>`__ is not available.  The Connect `packaging model <https://docs.confluent.io/current/connect/devguide.html#packaging>`__ will require that you deploy an archive containing your custom JAR to the `Kafka Connect's plugin path <https://docs.confluent.io/current/connect/userguide.html#connect-installing-plugins>`__.

This demonstration utilizes a `custom Connector to generate mock events <https://github.com/confluentinc/kafka-connect-datagen>`__ which is **not** installed by default in the Confluent Kafka Connect Docker images.  In order to utilize this plugin, we build a custom Docker image which is derived from the Confluent Operator based Docker image and install the custom connector using the ``confluent-hub`` client.

Here is the ``Dockerfile`` snippet used to build these images (`source <https://github.com/confluentinc/kafka-connect-datagen/blob/0.1.x/Dockerfile-operator-local>`__):

::

  ARG CP_VERSION

  FROM confluentinc/cp-server-connect-operator:${CP_VERSION}.0

  ARG KAFKA_CONNECT_DATAGEN_VERSION

  COPY target/components/packages/confluentinc-kafka-connect-datagen-${KAFKA_CONNECT_DATAGEN_VERSION}.zip /tmp/confluentinc-kafka-connect-datagen-${KAFKA_CONNECT_DATAGEN_VERSION}.zip

  RUN confluent-hub install --no-prompt /tmp/confluentinc-kafka-connect-datagen-${KAFKA_CONNECT_DATAGEN_VERSION}.zip

The `confluentinc/cp-server-connect-operator <https://hub.docker.com/r/confluentinc/cp-server-connect-operator>`__ image is used as the Base image upon which the ``confluent-hub`` client is used to install the custom connector.   See the documentation on `confluent-hub client <https://docs.confluent.io/current/connect/managing/confluent-hub/client.html>`__ for details for `installing from Confluent Hub <https://docs.confluent.io/current/connect/managing/confluent-hub/client.html#installing-components-with-c-hub-client>`__ or from a `local archive <https://docs.confluent.io/current/connect/managing/confluent-hub/command-reference/confluent-hub-install.html#confluent-hub-client-install>`__.

Once the Docker image is built with your custom archive installed, Kubernetes will need to be able to pull this image from a Docker Registry to create the Pods.  The demonstration accomplishes this by publishing the image to `Docker Hub <https://hub.docker.com/r/cnfldemos/cp-server-connect-operator-with-datagen>`__.

Finally your Operator Helm values will need to be updated to pull the custom images for your Pods.  This demo accomplishes this by overriding the ``connect`` image repository like so:

::

  connect:
  image:
    repository: cnfldemos/cp-server-connect-operator-with-datagen 
    tag: 0.1.6-5.3.1.0

See the demo's `value.yaml <https://github.com/confluentinc/examples/blob/5.3.1-post/kubernetes/gke-base/cfg/values.yaml#L53>`__ file and the `kafka-connect-datagen <https://github.com/confluentinc/kafka-connect-datagen>`__ GitHub repository for the full example.

