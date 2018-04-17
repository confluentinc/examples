![image](../images/confluent-logo-300-2.png)

# Overview

The MySQL Debezium demo shows an end-to-end streaming ETL with KSQL for stream processing. This demo uses the [Debezium Connector for MySQL](http://debezium.io/docs/connectors/mysql/)

![](images/ksql-debezium-es.png)

# Prerequisites

* [Common demo prerequisites](https://github.com/confluentinc/quickstart-demos#prerequisites)
* [Confluent Platform 4.1](https://www.confluent.io/download/)
* MySQL
  * [Binary log should be enabled](http://debezium.io/docs/connectors/mysql/)
* Elasticsearch 5.6.5 to export data from Kafka
  * If you do not want to use Elasticsearch, comment out ``check_running_elasticsearch`` in the ``start.sh`` script
* Kibana 5.5.2 to visualize data
  * If you do not want to use Kibana, comment out ``check_running_kibana`` in the ``start.sh`` script

# What Should I see?

After you run `./start.sh`:

* If you are running Confluent Enterprise, open your browser and navigate to the Control Center web interface Monitoring -> Data streams tab at http://localhost:9021/monitoring/streams to see throughput and latency performance of the KSQL queries
* Run `ksql http://localhost:8088` to view and create queries, or open your browser and navigate to the KSQL UI at http://localhost:8088
* Navigate to the Kibana dashboard at http://localhost:5601/app/kibana#/dashboard/Ratings

![image](images/kibana-dashboard.png)
