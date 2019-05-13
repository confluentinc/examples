![image](../images/confluent-logo-300-2.png)

# Overview

This demo showcases a AWS Kinesis -> Confluent Cloud -> Google Cloud Storage pipeline.

![image](images/topology.jpg)

Benefits:

* Span cloud providers and datacenters
* Leverage Kafka's rich ecosystem of a full event streaming platform
* Aggregate data in single source of truth
* Use power of KSQL


# Prerequisites

## Local

As with the other demos in this repo, you may run the entire demo end-to-end with `./start.sh`, and it runs on your local Confluent Platform install.  This requires the following:

* [Common demo prerequisites](https://github.com/confluentinc/examples#prerequisites)
* [Confluent Platform 5.2](https://www.confluent.io/download/)
* [An initialized Confluent Cloud cluster used for development only](https://confluent.cloud)
* AWS related requirements
  * `aws cli`
  * AWS properly credentials configured on your host
  * Access to Kinesis S3
* `jq`
* `curl`


# Run the demo

1. Run the demo:

```bash
$ ./start.sh
```

2. View all the Kinesis, Kafka, and cloud storage after bring-up:

```bash
$ ./read-data.sh
```

3. Stop the demo and clean up:

```bash
$ ./stop.sh
```
