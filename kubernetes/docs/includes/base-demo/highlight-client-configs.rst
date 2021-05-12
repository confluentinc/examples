Client Configurations
`````````````````````

.. warning:: The default security deployment for the |cp| Helm Charts is to use SASL/PLAIN security.  This is useful for demonstration purposes, however, you should use greater security for production environments.  See `Configuring security <https://docs.confluent.io/operator/current/co-security.html>`__ for more details.

Using the |cp| `Helm Charts <https://github.com/confluentinc/cp-helm-charts>`__, |ak| is deployed with Plaintext SASL security enabled.  In order for clients to authenticate, they will require configuration values including SASL credentials.   The Kubernetes API supports `Secrets <https://kubernetes.io/docs/concepts/configuration/secret/>`__ and `ConfigMap <https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/>`__ types which can be used to push configuration values into files that applications on Pods can use.   This demo uses these mechanisms to launch a ``client-console`` Pod preconfigured with the required client properties file.  The properties file on the Pod is a mapped version of the centrally stored Secret.  

Here is how it works:

The configuration file values, including the SASL secrets, are defined in a Kubernetes Object file, like the following.  Note how everything beyond the ``kafka-client.properties`` line looks like a typical Java Properties file::

  apiVersion: v1
  kind: Secret
  metadata:
    name: kafka-client.properties
  type: Opaque
  stringData:
    kafka-client.properties: |-
      bootstrap.servers=kafka:9071
      sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test" password="test123";
      sasl.mechanism=PLAIN
      security.protocol=SASL_PLAINTEXT

The demo applies this object to the cluster with the ``kubectl apply`` command::

	kubectl --context <k8s-context> -n operator apply -f <path-to-examples-repo>kubernetes/common/cfg/kafka-client-secrets.yaml

The ``client-console`` is deployed with this Secret Object mapped as a volume to the Pod::

  apiVersion: v1
  kind: Pod
  metadata:
    namespace: operator
    name: client-console
  spec:
    containers:
    - name: client-console
      image: docker.io/confluentinc/cp-server-operator:5.3.0.0
      command: [sleep, "86400"]
      volumeMounts:
      - name: kafka-client-properties
        mountPath: /etc/kafka-client-properties/
    volumes:
    - name: kafka-client-properties
      secret:
        secretName: kafka-client.properties

The end result is the Secret object named ``kafka-client.properties`` is located on the Pod in the file location ``/etc/kafka-client-properties/kafka-client.properties``::

	kubectl -n operator exec -it client-console bash

	root@client-console:/opt# cat /etc/kafka-client-properties/kafka-client.properties
	bootstrap.servers=kafka:9071
	sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test" password="test123";
	sasl.mechanism=PLAIN
	security.protocol=SASL_PLAINTEXT
