|ccloud| Account Setup
+++++++++++++++++++++++++++++

This demonstration requires that you have a |ccloud| account and a |ak| cluster ready for use.  The `Confluent Cloud <https://www.confluent.io/confluent-cloud/>`__ home page can help you get setup with your own account if you do not yet have access.   

.. note:: This demonstration highlights a multi-cloud replication strategy using |crep-full|.  One benefit of |crep| is that the destination cluster topics and partitions will be identical in message offsets, timestamps, keys, and values.   If you re-use a cluster with an existing ``stock-trades`` topic, the messages will be appended to the end of the existing topic data and the offsets will not match the source cluster.  It's advised to build a new cluster for each run of this example, or delete the ``stock-trades`` |ak| topic in the destination cluster prior to running.  See: `ccloud kafka topic delete <https://docs.confluent.io/ccloud-cli/current/command-reference/kafka/topic/ccloud_kafka_topic_delete.html>`__ for instructions on deleting |ccloud| topics.

|ak| Cluster Setup
+++++++++++++++++++

If you are creating a new cluster, it is advised to create it within the same Cloud Provider and region as this example.  This demonstration runs on top of Azure and, by default, in the ``centralus`` region.  It is recommended to name your new cluster ``replicator-aks-cc-demo`` to match names used later in this example.  The following illustrates the recommended configuration:

.. figure:: images/new-cluster-1.png
    :alt: New Cluster Example

.. figure:: images/new-cluster-2.png
    :alt: New Cluster Example

.. figure:: images/new-cluster-3.png
    :alt: New Cluster Example

.. tip:: See the `Confluent Cloud Quick Start <https://docs.confluent.io/cloud/current/get-started/index.html>`__ for more information.

|ak| Bootstrap Server Configuration
++++++++++++++++++++++++++++++++++++

After you have established the |ccloud| cluster you are going to use for the example you will need the public bootstrap server.

You can use the ``ccloud`` CLI to retrieve the bootstrap server value for your cluster.

.. tip:: You can also view the bootstrap server value on the |ccloud| UI under the **Cluster settings**
  
  |cluster-settings| 

#.  If you haven't already, `install the ccloud CLI <https://docs.confluent.io/ccloud-cli/current/install.html>`__

#.  Log in to your |ccloud| cluster. The ``--save`` argument saves your |ccloud| user login credentials or refresh token (in the case of SSO) to the local ``netrc`` file.

    ::

        ccloud login --save

    Your output should resemble:

    ::

        Enter your Confluent credentials:
        Email: jdoe@myemail.io
        Password:
        
        Logged in as jdoe@myemail.io
        Using environment t118 ("default")

#.  List your available |ak| clusters.

    ::

        ccloud kafka cluster list

    This should produce a list of clusters you have access to:

    ::

              Id      |          Name          | Provider |   Region    | Durability | Status  
        +-------------+------------------------+----------+-------------+------------+--------+
            lkc-xmm5g | abc-test               | azure    | centralus   | LOW        | UP      
            lkc-kngnv | rjs-azure-centralus    | azure    | centralus   | LOW        | UP      
            lkc-3r3vj | replicator-aks-cc-demo | azure    | centralus   | LOW        | UP      

#.  Describe the cluster to obtain the bootstrap server

    ::

        ccloud kafka cluster describe lkc-3r3vj

    This will produce a detailed view of the cluster.  The ``Endpoint`` field contains the bootstrap server value

    ::

        +-------------+------------------------------------------------------------+
        | Id          | lkc-3r3vj                                                  |
        | Name        | replicator-aks-cc-demo                                     |
        | Type        | BASIC                                                      |
        | Ingress     |                                                        100 |
        | Egress      |                                                        100 |
        | Storage     |                                                       5000 |
        | Provider    | azure                                                      |
        | Region      | centralus                                                  |
        | Status      | UP                                                         |
        | Endpoint    | SASL_SSL://abc-12345.centralus.azure.confluent.cloud:9092  |
        | ApiEndpoint | https://abc-12345.centralus.azure.confluent.cloud          |
        +-------------+------------------------------------------------------------+

API Key and Secret Configuration
++++++++++++++++++++++++++++++++

The ``ccloud`` CLI allows you to create API Keys to be used with client applications.

.. tip:: You can also create the API Key using the `Confluent Cloud UI <https://docs.confluent.io/cloud/using/api-keys.html#edit-resource-specific-api-key-descriptions-using-the-ui>`__.

#.  To create a new API Key:

    ::

        ccloud api-key create --resource lkc-3r3vj

    The tool will display a new Key and secret as below.  You will need to save these values elsewhere as they cannot be retrieved later.

    ::

        Save the API key and secret. The secret is **not** retrievable later.
        +---------+------------------------------------------------------------------+
        | API Key | LD35EM2YJTCTRQRM                                                 |
        | Secret  | 67JImN+9vk+Hj3eaj2/UcwUlbDNlGGC3KAIOy5JNRVSnweumPBUpW31JWZSBeawz |
        +---------+------------------------------------------------------------------+

Configure Helm Values
+++++++++++++++++++++

To configure the example to access your |ccloud| account, we are going to create a `Helm Chart <https://helm.sh/docs/chart_template_guide/>`__ values file, which the example looks for in a particular location to pass to ``helm`` commands to weave your cloud account details into the configuration of the |cp| configurations.

#.  Create a values file by executing the following command, first replacing the ``{{ mustache bracket }}`` values for  ``bootstrapEndpoint``, ``username``, and ``password`` with your relevant values obtained above. 

    ::

        cat <<'EOF' > ./cfg/my-values.yaml
        destinationCluster: &destinationCluster
          name: replicator-aks-cc-demo
          tls:
            enabled: true
            internal: true
            authentication:
              type: plain
          bootstrapEndpoint: {{ cloud bootstrap server }}
          username: {{ cloud API key }}
          password: {{ cloud API secret }}
        
        controlcenter:
          dependencies:
            monitoringKafkaClusters:
            - <<: *destinationCluster
        
        replicator:
          replicas: 1
          dependencies:
            kafka:
              <<: *destinationCluster
        EOF

    You can now verify the values of the file prior to running the example.  The example `Makefile` will integrate these values into the Helm deployment.

    ::

        cat ./cfg/my-values.yaml
