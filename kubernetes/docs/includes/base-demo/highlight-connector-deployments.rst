Connector Deployments
`````````````````````

|kconnect-long| utilizes a `REST endpoint <https://docs.confluent.io/platform/current/connect/references/restapi.html>`__, which accepts JSON objects, for Connector deployments.  This demo shows one approach for deploying a connector inside the Kubernetes cluster using Kubernetes `ConfigMap <https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/>`__ objects, a standard Docker image with an overridden command, and the Kubernetes `Batch Job API <https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/>`__.

First the connector definition is defined inside a ConfigMap object.  Notice how everything after the ``clicks-datagen-connector.json`` name is a full JSON object::

	apiVersion: v1
	kind: ConfigMap
	metadata:
	  name: clicks-datagen-connector
	data:
	  clicks-datagen-connector.json: '{
	    "name":"clicks",
	    "config": {
	      "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
	      "kafka.topic": "clicks",
	      "key.converter": "org.apache.kafka.connect.storage.StringConverter",
	      "value.converter": "io.confluent.connect.avro.AvroConverter",
	      "value.converter.schema.registry.url": "http://schemaregistry:8081",
	      "value.converter.schemas.enable": "true",
	      "quickstart": "clickstream",
	      "max.interval": 1000,
	      "iterations": -1,
	      "tasks.max": "1"
	    }
	  }'

This ConfigMap is applied to the cluster with the following command::

	kubectl --context <k8s-context> -n operator apply -f <path-to-examples-repo>kubernetes/common/cfg/clicks-datagen-connector-configmap.yaml

Next, a Kubernetes Job Object is defined.  Using a docker image with the ``curl`` program installed, the Job adds arguments to the ``curl`` command in order to deploy the connector configuration.  Note how the ConfigMap defined above is mounted to the Job specification and the config file passed into the ``curl`` command matches the path of the file mounted::

	apiVersion: batch/v1
	kind: Job
	metadata:
	  name: clicks-datagen-connector-deploy
	spec:
	  ttlSecondsAfterFinished: 5
	  template:
	    spec:
	      volumes:
	      - name: clicks-datagen-connector
	        configMap:
	          name: clicks-datagen-connector
	      containers:
	      - name: clicks-datagen-connector-deploy
	        image: cnfldemos/alpine-curl:3.10.2_7.65.1
	        args: [ 
	          "-s",
	          "-X", "POST",
	          "-H", "Content-Type: application/json",
	          "--data", "@/etc/config/connector/clicks-datagen-connector.json",
	          "http://connectors:8083/connectors"
	        ]
	        volumeMounts:
	          - name: clicks-datagen-connector
	            mountPath: /etc/config/connector
	      restartPolicy: Never
	  backoffLimit: 1

The job is applied to the cluster, after the Kafka Connect system is deployed with::

	kubectl --context <k8s-context> -n operator apply -f <path-to-examples-repo>kubernetes/common/cfg/clicks-datagen-connector-deploy-job.yaml

After the job is applied, the following command shows the deployed connector::

	kubectl -n operator exec -it client-console bash
	root@client-console:/opt# curl http://connectors:8083/connectors;echo;
	["clicks"]

.. include:: ../../docs/includes/deploy-jars-k8s.rst
