Deploying Connectors with Operator 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can deploy any Kafka connector (or `single message transformation (SMT) <https://docs.confluent.io/platform/current/connect/concepts.html#transforms>`__ or `converter <https://docs.confluent.io/platform/current/connect/concepts.html#converters>`__) in your Kubernetes environment.
Search in `Confluent Hub <https://confluent.io/hub>`__, an online library of pre-packaged and ready-to-install connectors, transformations, and converters, to find the one that suits your needs.
The |co-long| image for |kconnect-long|, `confluentinc/cp-server-connect-operator <https://hub.docker.com/r/confluentinc/cp-server-connect-operator>`__,  includes a small number of those connectors but may not have the specific connector you want to deploy.
Therefore, to deploy a new connector type in your Kubernetes environment, you will need to get the jars onto the Connect image.

The recommended way is to create a custom Docker image that extends the base Connect Docker image with the desired jars.
The custom Docker image builds the dependencies into a single artifact, which is more self-sufficient and portable such that it can be run on any pod despite totally ephemeral disk.
See the `documentation <https://docs.confluent.io/home/connect/extending.html#create-a-docker-image-containing-c-hub-connectors>`__ to learn how to use the |c-hub| client to create a custom Docker image that extends one of Confluent’s Kafka Connect images with a specific set of ready-to-install connectors.
As an example, see how the `Kafka Connect Datagen connector <https://www.confluent.io/hub/confluentinc/kafka-connect-datagen>`__, which generates mock events, can be pulled from |c-hub| and bundled into a Docker image using this `Dockerfile <https://github.com/confluentinc/kafka-connect-datagen/blob/master/Dockerfile-confluenthub>`__.
Once you build the custom Docker image, Kubernetes will need to pull this image from a Docker Registry to create the Pods.

.. note:: It is not recommended to use volumes to place the desired jars onto the Connect image because it is less self-sufficient, less portable, and harder to match up versions between the base image and jars.

For more advanced use cases where you want to use a custom connector instead of a pre-packaged one available at |c-hub|, you may create a Docker image with a custom connector from a `local archive <https://docs.confluent.io/home/connect/confluent-hub/command-reference/confluent-hub-install.html>`__.
The demonstration uses this more advanced workflow.
We use the `Kafka Connect Datagen connector <https://www.confluent.io/hub/confluentinc/kafka-connect-datagen>`__ to generate mock events, and this `Dockerfile <https://github.com/confluentinc/kafka-connect-datagen/blob/master/Dockerfile-local>`__ builds the Docker image with a local archive of the Kafka Connect Datagen connector compiled from source code (versus pulling directly from |c-hub|).
We publish this image to `Docker Hub <https://hub.docker.com/r/cnfldemos/cp-server-connect-operator-with-datagen>`__, but in your environment, publish to your own Docker Hub repo.

Your Operator Helm values will need to be updated to pull the custom Connect Docker image for your Pods. You can accomplish this by overriding the ``connect`` image to instead use the one published to Docker Hub in the demo's value.yaml configuration file.

::

  connect:
  image:
    repository: cnfldemos/cp-server-connect-operator-datagen
    tag: 0.3.1-5.4.1.0
