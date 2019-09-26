# Clojure Producer and Consumer for Confluent Cloud

This directory includes projects demonstrating how to use Java interop
form Clojure to produce and consume with Confluent Cloud.

For more information, please see the [application development documentation](https://docs.confluent.io/current/api-javadoc.html)

# Prerequisites

* Installed [Leiningen](https://leiningen.org/#install) tool
* Access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/) cluster
* Initialize a properties file at `$HOME/.ccloud/config` with configuration to your Confluent Cloud cluster:

```shell
$ cat $HOME/.ccloud/config
bootstrap.servers=<BROKER ENDPOINT>
ssl.endpoint.identification.algorithm=https
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";

# Quickstart

Once the above prerequisites are fulfilled, we can launch a Clojure REPL and start can start running the examples in this directory.

   1. Run the consumer:
   ```shell
   $ cd examples/clients/clojd/clojure
   $ lein consumer $HOME/.ccloud/config testtopic
   …
   Polling
   …
   ```

   2. In a seperate window, run the producer:
   ```shell
   $ cd examples/clients/clojd/clojure
   $ lein producer $HOME/.ccloud/config testtopic
   …
   Produced record at testtopic-0@0
   Produced record at testtopic-0@1
   Produced record at testtopic-0@2
   Produced record at testtopic-0@3
   Produced record at testtopic-0@4
   Produced record at testtopic-0@5
   Produced record at testtopic-0@6
   Produced record at testtopic-0@7
   Produced record at testtopic-0@8
   Produced record at testtopic-0@9
   Wrote ten records to  testtopic
   ```

   In the consumer window you should see:
   ```
   <snip>
   Polling
   Consumed record with key alice and value {"count":1}, total count is 1
   Consumed record with key alice and value {"count":2}, total count is 3
   Consumed record with key alice and value {"count":3}, total count is 6
   Consumed record with key alice and value {"count":4}, total count is 10
   Consumed record with key alice and value {"count":5}, total count is 15
   Polling
   Consumed record with key alice and value {"count":6}, total count is 21
   Consumed record with key alice and value {"count":7}, total count is 28
   Consumed record with key alice and value {"count":8}, total count is 36
   Consumed record with key alice and value {"count":9}, total count is 45
   Consumed record with key alice and value {"count":10}, total count is 55
   Polling
   <snip>
   ```

   Hit Ctrl+C in the consumer windows to stop it.
