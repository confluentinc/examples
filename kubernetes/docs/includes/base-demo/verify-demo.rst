Verify the Kubernetes Deployment
````````````````````````````````

You can view the deployed components with:

.. sourcecode:: bash

    kubectl -n operator get all

Using the default example variable values, ``kubectl`` should report something like the following

::

	NAME                                        READY   STATUS      RESTARTS   AGE
	pod/cc-operator-76c54d65cd-28czd            1/1     Running     0          11m
	pod/clicks-datagen-connector-deploy-2vd8q   0/1     Completed   0          8m6s
	pod/connectors-0                            1/1     Running     0          9m36s
	pod/controlcenter-0                         1/1     Running     0          8m4s
	pod/client-console                          1/1     Running     0          10m
	pod/kafka-0                                 1/1     Running     0          10m
	pod/schemaregistry-0                        1/1     Running     0          9m59s
	pod/zookeeper-0                             1/1     Running     0          11m

	NAME                                TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                                        AGE
	service/connectors                  ClusterIP   None          <none>        8083/TCP,7203/TCP,7777/TCP                     9m36s
	service/connectors-0-internal       ClusterIP   10.0.8.147    <none>        8083/TCP,7203/TCP,7777/TCP                     9m36s
	service/controlcenter               ClusterIP   None          <none>        9021/TCP,7203/TCP,7777/TCP                     8m5s
	service/controlcenter-0-internal    ClusterIP   10.0.14.242   <none>        9021/TCP,7203/TCP,7777/TCP                     8m5s
	service/kafka                       ClusterIP   None          <none>        9071/TCP,9072/TCP,9092/TCP,7203/TCP,7777/TCP   10m
	service/kafka-0-internal            ClusterIP   10.0.14.239   <none>        9071/TCP,9072/TCP,9092/TCP,7203/TCP,7777/TCP   10m
	service/schemaregistry              ClusterIP   None          <none>        8081/TCP,7203/TCP,7777/TCP                     10m
	service/schemaregistry-0-internal   ClusterIP   10.0.6.93     <none>        8081/TCP,7203/TCP,7777/TCP                     10m
	service/zookeeper                   ClusterIP   None          <none>        3888/TCP,2888/TCP,2181/TCP,7203/TCP,7777/TCP   11m
	service/zookeeper-0-internal        ClusterIP   10.0.8.51     <none>        3888/TCP,2888/TCP,2181/TCP,7203/TCP,7777/TCP   11m

	NAME                          DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
	deployment.apps/cc-operator   1         1         1            1           11m

	NAME                                     DESIRED   CURRENT   READY   AGE
	replicaset.apps/cc-operator-76c54d65cd   1         1         1       11m

	NAME                              DESIRED   CURRENT   AGE
	statefulset.apps/connectors       1         1         9m36s
	statefulset.apps/controlcenter    1         1         8m4s
	statefulset.apps/kafka            1         1         10m
	statefulset.apps/schemaregistry   1         1         9m59s
	statefulset.apps/zookeeper        1         1         11m

	NAME                                        COMPLETIONS   DURATION   AGE
	job.batch/clicks-datagen-connector-deploy   1/1           4s         8m6s

	NAME                                               AGE
	zookeepercluster.cluster.confluent.com/zookeeper   11m

	NAME                                       AGE
	kafkacluster.cluster.confluent.com/kafka   10m

Verify Confluent Platform on the CLI 
````````````````````````````````````

By default the example is deployed without any `Kubernetes Ingress <https://kubernetes.io/docs/concepts/services-networking/ingress/>`__, which means the |cp| resources inside the Kubernetes cluster cannot be reached from external clients.  If you used a pre-existing cluster with Ingress enabled, the following validation instructions may not be applicable to your setup.

The example deploys a ``client-console`` pod that can be used to open a terminal inside the cluster with network connectivity to the |cp| services.  For example::

	kubectl -n operator exec -it client-console -- bash

From here you can execute standard |ak| commands to validate the cluster.  You need to provide the commands with the required connectivity and security configurations, which are provided in mapped files on the ``client-console`` pod.  See the :ref:`examples-operator-base-client-configurations` Highlight for more information.

.. sourcecode:: bash

		kafka-topics --bootstrap-server kafka:9071 --command-config /etc/kafka-client-properties/kafka-client.properties --list

You could view the output of the mock click data generator with the console consumer::

	kafka-console-consumer --bootstrap-server kafka:9071 --consumer.config /etc/kafka-client-properties/kafka-client.properties --topic clicks

Example output might look like::

	222.152.45.45F-
	16141<GET /images/track.png HTTP/1.1204006-Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36
	122.173.165.203L-
	16151FGET /site/user_status.html HTTP/1.1401289-Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)
	...

Verify Confluent Platform Control Center
````````````````````````````````````````
.. include:: ../../docs/includes/port-forward-c3.rst

Now open a web-browser to http://localhost:12345, and you should see |c3| with your operational |ak| cluster, |sr|, and |kconnect-long| with the running ``clicks`` connector.

.. figure:: ../../docs/images/clicks-inspection.png
    :alt: c3

