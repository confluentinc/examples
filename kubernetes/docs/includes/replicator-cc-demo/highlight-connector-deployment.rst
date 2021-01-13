Deploying Kafka Connectors with Helm
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following highlights a simple Helm chart that can be used to deploy |kconnect-long| Connector configurations using the standard `Kafka Connect REST Interface <https://docs.confluent.io/platform/current/connect/references/restapi.html>`__.  This is how this demonstration deploys the |crep-full| configuration, however, the same method could be used to deploy any |kconnect-long| configuration.  In future versions of |co-long|, |kconnect-long| connectors will be managed by the Operator `Controller <https://kubernetes.io/docs/concepts/architecture/controller/>`__.

The Helm chart is located in the ``kubernetes/common/helm/replicator-cc`` folder of this demonstration.  The ``templates/replicator-configmap.yaml`` file contains a ``data`` section with a templated JSON value that conforms to the |kconnect-long| `connectors API <https://docs.confluent.io/platform/current/connect/references/restapi.html#post--connectors>`__.  The Destination and Source cluster configuration values are filled in at runtime by the ``helm`` templating system, and are proivded by your ``my-values.yaml`` file created in the demo instructions above.

:: 

     apiVersion: v1
     kind: ConfigMap
     metadata:
       name: replicator-connector
     data:
       replicator-connector.json: '{
         "name":"replicator",
         "config": {
           "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
           "topic.whitelist": "{{.Values.replicator.topic.whitelist}}",
           "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
           "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
           "dest.kafka.bootstrap.servers": "{{.Values.replicator.dependencies.kafka.bootstrapEndpoint}}",
           "dest.kafka.security.protocol": "{{$destProtocol}}",
           "dest.kafka.sasl.mechanism": "PLAIN",
           "dest.kafka.sasl.jaas.config": "{{$destJaasConfig}}",
           "src.consumer.group.id": "replicator",
           "src.kafka.bootstrap.servers": "kafka:9071",
           "src.kafka.security.protocol": "{{$srcProtocol}}",
           "src.kafka.sasl.mechanism": "PLAIN",
           "src.kafka.sasl.jaas.config": "{{$srcJaasConfig}}",
           "src.consumer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor",
           "src.consumer.confluent.monitoring.interceptor.bootstrap.servers": "kafka:9071",
           "src.consumer.confluent.monitoring.interceptor.security.protocol": "{{$srcProtocol}}",
           "src.consumer.confluent.monitoring.interceptor.sasl.mechanism": "PLAIN",
           "src.consumer.confluent.monitoring.interceptor.sasl.jaas.config": "{{$srcJaasConfig}}",
           "src.kafka.timestamps.producer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor",
           "src.kafka.timestamps.producer.confluent.monitoring.interceptor.bootstrap.servers": "kafka:9071",
           "src.kafka.timestamps.producer.confluent.monitoring.interceptor.security.protocol": "{{$srcProtocol}}",
           "src.kafka.timestamps.producer.confluent.monitoring.interceptor.sasl.mechanism": "PLAIN",
           "src.kafka.timestamps.producer.confluent.monitoring.interceptor.sasl.jaas.config": "{{$srcJaasConfig}}",
           "tasks.max": "1"
         }
       }'

In the same directory as the ConfigMap manifest file is a `Kubernetes Job <https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/>`__ manifest (``replicator-connector-deploy-job.yaml``).  This defines a Kubernetes `Job <https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/>`__ that will successfully execute a job to completion and terminate.  Using a Docker image that contains the ``curl`` program, the ConfigMap defined above is mounted to the batch job Pod, and then ``curl`` executes a ``POST`` to the |kconnect-long| REST API to deploy |crep|.

::

    apiVersion: batch/v1
    kind: Job
    metadata:
      name: replicator-connector-deploy
    spec:
      ttlSecondsAfterFinished: 5
      template:
        spec:
          volumes:
          - name: replicator-connector
            configMap:
              name: replicator-connector
          containers:
          - name: replicator-connector-deploy
            image: cnfldemos/alpine-curl:3.10.2_7.65.1
            args: [ 
              "-s",
              "-X", "POST",
              "-H", "Content-Type: application/json",
              "--data", "@/etc/config/connector/replicator-connector.json",
              "http://replicator:8083/connectors"
            ]
            volumeMounts:
              - name: replicator-connector
                mountPath: /etc/config/connector
          restartPolicy: Never
      backoffLimit: 1

Of note is the way in which the ConfigMap is associated to the Job Pod by name.  The value, ``replicator-connector`` in the ``volumes`` stanza of the Job manifest matches the ConfigMap name in the metadata section of the ConfigMap manifest.
