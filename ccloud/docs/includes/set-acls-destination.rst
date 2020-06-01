|crep| must have authorization to read |ak| data from the origin cluster and write |ak| data in the destination |ccloud| cluster.
|crep| should be run with a |ccloud| service account, not super user credentials, so use |ccloud| CLI to configure appropriate ACLs for the service account id corresponding to |crep| in |ccloud|.
For more details on |crep| ACLs, see :ref:`replicator_security_overview`.

.. sourcecode:: bash

   ccloud kafka acl create --allow --service-account <service-account-id> --operation CREATE --topic <replicated-topic>
   ccloud kafka acl create --allow --service-account <service-account-id> --operation WRITE --topic <replicated-topic>
   ccloud kafka acl create --allow --service-account <service-account-id> --operation READ --topic <replicated-topic>
   ccloud kafka acl create --allow --service-account <service-account-id> --operation DESCRIBE --topic <replicated-topic>
   ccloud kafka acl create --allow --service-account <service-account-id> --operation DESCRIBE-CONFIGS --topic <replicated-topic>
   ccloud kafka acl create --allow --service-account <service-account-id> --operation ALTER-CONFIGS --topic <replicated-topic>
   ccloud kafka acl create --allow --service-account <service-account-id> --operation DESCRIBE --cluster-scope

