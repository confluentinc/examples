# Overview

Produce messages to and consume messages from [Confluent Cloud](https://www.confluent.io/confluent-cloud/) using the .NET Producer and Consumer.


# Prerequisites

* .NET Core 2.1 or higher to run the demo application.
* [Confluent Cloud CLI](https://docs.confluent.io/current/cloud/cli/install.html) installed on your machine. It is provided as part of the Confluent Platform package or may be [installed separately](https://docs.confluent.io/current/cloud/cli/install.html).
* Access to a [Confluent Cloud](https://www.confluent.io/confluent-cloud/) cluster
* [Initialize](https://docs.confluent.io/current/cloud/cli/multi-cli.html#connect-ccloud-cli-to-a-cluster) your local Confluent Cloud configuration file using the `ccloud init` command, which creates the file at `$HOME/.ccloud/config` (`%HOMEPATH%/.ccloud/config` on Windows).

# Example

In this example, the producer writes records to a topic in Confluent Cloud. 
Each record has a key representing a username (e.g. `alice`) and a value of a count, formatted as json (e.g. `{"count": 0}`).
The consumer reads the same topic from Confluent Cloud and keeps a rolling sum of the counts as it processes each record.

## Produce Records

Run the example application, passing in arguments for (a) whether to produce or consume (produce) (b) the topic name (c) the local file with configuration parameters to connect to your Confluent Cloud instance and (d, Windows only) a local file with default trusted root CA certificates. 

> Note: On Windows, default trusted root CA certificates - which are required for secure access to Confluent Cloud - are stored in the Windows Registry. The .NET library does not currently have the capability to access these certificates, so you will need to obtain them from somewhere else, for example use the cacert.pem file distributed with curl: https://curl.haxx.se/ca/cacert.pem. 


```shell
# Build the client example application
$ dotnet build

# Run the producer (Windows)
$ dotnet run produce test1 %HOMEPATH%/.ccloud/config /path/to/curl/cacert.pem

# Run the producer (other)
$ dotnet run produce test1 $HOME/.ccloud/config
```

You should see:

```shell
Producing record: alice	{"count":0}
Producing record: alice	{"count":1}
Producing record: alice	{"count":2}
Producing record: alice	{"count":3}
Producing record: alice	{"count":4}
Producing record: alice	{"count":5}
Producing record: alice	{"count":6}
Producing record: alice	{"count":7}
Producing record: alice	{"count":8}
Producing record: alice	{"count":9}
Produced record to topic test1 partition [0] @ offset 0
Produced record to topic test1 partition [0] @ offset 1
Produced record to topic test1 partition [0] @ offset 2
Produced record to topic test1 partition [0] @ offset 3
Produced record to topic test1 partition [0] @ offset 4
Produced record to topic test1 partition [0] @ offset 5
Produced record to topic test1 partition [0] @ offset 6
Produced record to topic test1 partition [0] @ offset 7
Produced record to topic test1 partition [0] @ offset 8
Produced record to topic test1 partition [0] @ offset 9
10 messages were produced to topic test1
```

## Consume Records

Run the consumer, passing in arguments for (a) whether to produce or consume (consume) (b) the same topic name as used above (c) the local file with configuration parameters to connect to your Confluent Cloud instance and (d, Windows only) a local file with default trusted root CA certificates. Verify that the consumer received all the messages:

```shell
# Run the producer (Windows)
$ dotnet run consume test1 %HOMEPATH%/.ccloud/config /path/to/curl/cacert.pem

# Run the producer (other)
$ dotnet run consume test1 $HOME/.ccloud/config
```

You should see:

```
Consumed record with key alice and value {"count":0}, and updated total count to 0
Consumed record with key alice and value {"count":1}, and updated total count to 1
Consumed record with key alice and value {"count":2}, and updated total count to 3
Consumed record with key alice and value {"count":3}, and updated total count to 6
Consumed record with key alice and value {"count":4}, and updated total count to 10
Consumed record with key alice and value {"count":5}, and updated total count to 15
Consumed record with key alice and value {"count":6}, and updated total count to 21
Consumed record with key alice and value {"count":7}, and updated total count to 28
Consumed record with key alice and value {"count":8}, and updated total count to 36
Consumed record with key alice and value {"count":9}, and updated total count to 45
```

When you are done, press `<ctrl>-c`.
