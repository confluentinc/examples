Any |ccloud| example uses real |ccloud| resources that may be billable.
An example may create a new |ccloud| environment, |ak| cluster, topics, ACLs, and service accounts, as well as resources that have hourly charges like connectors and ksqlDB applications.
To avoid unexpected charges, carefully `evaluate the cost of resources <https://docs.confluent.io/cloud/current/billing/index.html>`__ before you start.
After you are done running a |ccloud| example, destroy all |ccloud| resources to avoid accruing hourly charges for services and verify that they have been deleted.
