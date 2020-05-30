|crep| must be authorized to read Kafka data from the origin cluster and write Kafka data in the destination |ccloud| cluster.
Best practices is that |crep| should be run with a |ccloud| service account, not super user credentials, so you will have to use |ccloud| CLI to configure appropriate ACLs for the service account id corresponding to |crep|.
Since the origin cluster in this example is also |ccloud|, you will have to also configure appropriate ACLs for the service account id corresponding to |crep| in the origin cluster as well as the destination cluster.
For more details on |crep| ACLs, see :ref:`replicator_security_overview`.

In the origin |ccloud|:

.. sourcecode:: bash

   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation CREATE --topic <topic-origin>
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation WRITE --topic <topic-origin>
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation READ --topic <topic-origin>
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation DESCRIBE --topic <topic-origin>
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation DESCRIBE-CONFIGS --topic <topic-origin>
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation ALTER-CONFIGS --topic <topic-origin>
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation DESCRIBE --cluster-scope
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation CREATE --cluster-scope


In the destination |ccloud|:

.. sourcecode:: bash

   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation CREATE --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation WRITE --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation READ --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation DESCRIBE --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation DESCRIBE-CONFIGS --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation ALTER-CONFIGS --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation DESCRIBE --cluster-scope
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation CREATE --cluster-scope

