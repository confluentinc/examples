![image](images/confluent-logo-300-2.png)

# Overview

There are multiple demos in this repo that showcase Kafka stream processing on the Confluent Platform.  Each demo resides in its own subfolder:

* [pageviews](pageviews/README.md)
* [music](music/README.md)
* [clickstream](clickstream/README.md)
* [wikipedia](wikipedia/README.md)
* [ratings](ratings/README.md)
* [connect-streams-pipeline](connect-streams-pipeline/README.md)
* [mysql-debezium](mysql-debezium/README.md)
* [ccloud](ccloud/README.md)
* [KSQL workshop](ksql-workshop/ksql-workshop.adoc)

# Running The Demos

1. Clone the repo: `git clone https://github.com/confluentinc/quickstart-demos`
2. Change directory to one of the demo subfolders
3. Start a demo with `./start.sh`
4. Stop a demo with `./stop.sh`

# Prerequisites

* [Confluent Platform 4.1](https://www.confluent.io/download/)
* Env var `CONFLUENT_HOME=/path/to/confluentplatform`
* Env var `PATH` includes `$CONFLUENT_HOME/bin`
* Internet connectivity to download the KSQL UI
  * If you do not want to download the KSQL UI, comment out ``get_ksql_ui`` in the demo's ``start.sh`` script
* Each demo has its own set of prerequisites as well, documented in each demo's README
