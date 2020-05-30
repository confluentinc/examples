Since the origin cluster in this example is also |ccloud|, you will have to also configure appropriate ACLs for the service account id corresponding to |crep| in the origin cluster.

   .. sourcecode:: bash

      ccloud kafka acl create --allow --service-account <service-account-id> --operation READ --topic <original-topic>
      ccloud kafka acl create --allow --service-account <service-account-id> --operation DESCRIBE-CONFIGS --topic <original-topic>

