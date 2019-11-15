Deploying Connectors with Operator 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The base |co-long| image for |kconnect-long|, `confluentinc/cp-server-connect-operator <https://hub.docker.com/r/confluentinc/cp-server-connect-operator>`__,  does not include any connector jars.
Therefore, to deploy any connector in your Kubernetes environment, you will need to create a custom Docker image that bundles the desired connector jars into the Connect image.
See the `documentation <https://docs.confluent.io/current/connect/managing/extending.html#create-a-docker-image-containing-c-hub-connectors>`__ to learn how to use the |c-hub| client to create a Docker image that extends one of Confluent’s Kafka Connect images with a specified set of connectors.
Once you build the custom Docker image, Kubernetes will need to be able to pull this image from a Docker Registry to create the Pods.

For more advanced use cases where you want to use a custom connector instead of a pre-built one available at |c-hub|, you may create a Docker image with this custom connector from a `local archive <https://docs.confluent.io/current/connect/managing/confluent-hub/command-reference/confluent-hub-install.html#confluent-hub-client-install>`__.
The demonstration uses this more advanced workflow.
The demo uses the `Kafka Connect Datagen connector <https://www.confluent.io/hub/confluentinc/kafka-connect-datagen>`__ to generate mock events.
We build a Docker image with the Kafka Connect Datagen connector that is locally compiled from source code, see the full `Dockerfile <https://github.com/confluentinc/kafka-connect-datagen/blob/0.1.x/Dockerfile-operator-local>`__.
Then the image is published to `Docker Hub <https://hub.docker.com/r/cnfldemos/cp-server-connect-operator-with-datagen>`__.

Your Operator Helm values will need to be updated to pull the custom Docker images for your Pods.
This demo accomplishes this by overriding the ``connect`` image to instead use the one published to Docker Hub, see `value.yaml <https://github.com/confluentinc/examples/blob/5.3.1-post/kubernetes/gke-base/cfg/values.yaml#L53>`__:

::

  connect:
  image:
    repository: cnfldemos/cp-server-connect-operator-with-datagen 
    tag: 0.1.6-5.3.1.0
