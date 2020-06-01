|crep| must have authorization to read |ak| data from the origin cluster and write |ak| data in the destination |ccloud| cluster.
|crep| should be run with a |ccloud| service account, not super user credentials, so use |ccloud| CLI to configure appropriate ACLs for the service account id corresponding to |crep|.
Since the origin cluster and destination cluster in this example are both |ccloud|, configure appropriate ACLs for the service account ids corresponding to |crep| in both |ccloud| clusters.
For more details on |crep| ACLs, see :ref:`replicator_security_overview`.

In the origin |ccloud|:

.. sourcecode:: bash

   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation CREATE --topic <topic-origin>
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation WRITE --topic <topic-origin>
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation READ --topic <topic-origin>
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation DESCRIBE --topic <topic-origin>
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation DESCRIBE-CONFIGS --topic <topic-origin>
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation DESCRIBE --cluster-scope
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation CREATE --topic __consumer_timestamps
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation WRITE --topic __consumer_timestamps
   ccloud kafka acl create --allow --service-account <service-account-id-origin> --operation DESCRIBE --topic __consumer_timestamps

In the destination |ccloud|:

.. sourcecode:: bash

   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation CREATE --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation WRITE --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation READ --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation DESCRIBE --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation DESCRIBE-CONFIGS --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation ALTER-CONFIGS --topic <topic-destination>
   ccloud kafka acl create --allow --service-account <service-account-id-destination> --operation DESCRIBE --cluster-scope

