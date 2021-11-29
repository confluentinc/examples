|crep| must have authorization to read |ak| data from the origin cluster and write |ak| data in the destination |ccloud| cluster.
|crep| should be run with a |ccloud| service account, not super user credentials, so use the Confluent CLI to configure appropriate ACLs for the service account id corresponding to |crep| in |ccloud|.

For details on how to configure these ACLs for |crep|, see :ref:`replicator_security_overview`.