To run the automated demo (estimated running time, 8 minutes):

.. sourcecode:: bash

    make demo

The demo will deploy |cp| leveraging |co-long|.   As the various components are deployed, the demonstration will echo the various commands as executing them so you can observe the process.  For example, the deployment message for |ak| will look similar to:

.. codewithvars:: bash

    +++++++++++++ deploy kafka
    helm upgrade --install --namespace operator --wait --timeout=500 -f examples/kubernetes/gke-base/cfg/values.yaml --set global.provider.region=us-central1 --set global.provider.kubernetes.deployment.zones={us-central1-a} -f examples/kubernetes/replicator-gke-cc/cfg/values.yaml -f examples/kubernetes/replicator-gke-cc/cfg/my-values.yaml  --set kafka.replicas=3 --set kafka.enabled=true kafka examples/kubernetes/common/cp/operator/20190912-v0.65.1/helm/confluent-operator
    Release "kafka" does not exist. Installing it now.
    NAME:   kafka
    LAST DEPLOYED: Mon Oct 28 11:42:07 2019
    NAMESPACE: operator
    STATUS: DEPLOYED
    ...
    ✔  ++++++++++ Kafka deployed

    +++++++++++++ Wait for Kafka
    source examples/kubernetes/common/bin/retry.sh; retry 15 kubectl --context |kubectl-context-pattern| -n operator get sts kafka
    NAME    READY   AGE
    kafka   0/3     1s
    kubectl --context |kubectl-context-pattern| -n operator rollout status statefulset/kafka
    Waiting for 3 pods to be ready...
    Waiting for 2 pods to be ready...
    Waiting for 1 pods to be ready...
    statefulset rolling update complete 3 pods at revision kafka-775f97f98b...
    ✔  ++++++++++ Kafka ready

The last output message you should see is:


.. codewithvars:: bash

    ✔ Replicator |k8s-service-name|->CC Demo running
