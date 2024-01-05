##  Writing Cloud Events to Confluent Cloud

[Cloud Events](https://github.com/cloudevents/spec) is a well-known standard for attaching Meta-Data to business relevant events. 

Cloud Events Metadata includes the following attributes amongst others: 
* logical producer (event source), 
* the subject (the person or thing) that an event pertains to, 
* an event identifier,
* the type of an event,
* the time when the event occurred. 

For the full set of attributes see the [specification](https://github.com/cloudevents/spec) 

In this example, use the online order domain as an example for sending Cloud Events data to 
Confluent Cloud and registering the schema with Confluent Schema Registry. 

A Cloud Event in the order domain could be an event for the creation of a new order. 
This cloud event could be serialized as follows in JSON: 

```
{
  "id": "614282a3-7818-48bf-8a74-85332e5579c7",
  "source": "/v1/orders",
  "specVersion": "1.0",
  "type": "io.confluent.samples.orders.created",
  "datacontenttype": "application/json",
  "dataschema": null,
  "subject": "60f9a967-077a-43ff-be2c-0c14c09bcb3a",
  "timestamp": 1653990696381,
  "data": {
    "productID": "21c2d736-56b4-4ddf-9dbf-5ebc3c79e126",
    "customerID": "68e5bde6-c5d5-488c-8469-8c9853d94589",
    "timestamp": 1653990696380
  }
}
```

#### Prerequisites

The following items are required to run this demo: 

* access to a Confluent Cloud cluster
* a Confluent Cloud API Key for Kafka
* a Confluent Cloud API Key for Schema Registry
* a recent version of Java and Javac
* a recent version of Apache Maven
* Access to Maven Central for downloading the dependencies

#### Running the Demo

* Create a topic named `order-cloud-events` either via the confluent CLI or via the Confluent Cloud UI. 
  A single partition is sufficient. 
* Copy `src/main/resources/application.properties.template` to `src/main/resources/application.properties`, 
  and fill in the bootstrap servers url, the schema registry url, your API keys and secrets for Kafka as well as for schema registry. 
* Compile the code: `mvn compile`
* run the SampleProducer application: `./run-sample-producer.sh`
* Go to the Confluent Cloud UI of your cluster, and inspect the messages produced to the topic, as well as the associated schema.  
