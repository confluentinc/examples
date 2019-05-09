![image](../images/confluent-logo-300-2.png)

# Overview

This demo showcases a Kinesis -> Kafka -> AWS S3 pipeline.

Benefits:

* Leverage rich ecosystem of a full streaming event platform
* Spans datacenters and cloud providers
* Aggregate data in single source of truth


# Prerequisites

## Local

As with the other demos in this repo, you may run the entire demo end-to-end with `./start.sh`, and it runs on your local Confluent Platform install.  This requires the following:

* [Common demo prerequisites](https://github.com/confluentinc/examples#prerequisites)
* [Confluent Platform 5.2](https://www.confluent.io/download/)
* [An initialized Confluent Cloud cluster used for development only](https://confluent.cloud)
* `jq`
* `aws cli`
* AWS credentials setup on your host

To run the local setup:

```bash
$ ./start.sh
```

