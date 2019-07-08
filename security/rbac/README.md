![image](../../images/confluent-logo-300-2.png)

# Overview

This demo showcases the Role Based Access Control (RBAC) and Identity Access Management (IAM) functionality in Confluent Platform. It is mostly for reference to see a workflow using the new functionality.

## Running the demo

First change directory into the scripts folder:

```bash
$ cd scripts
```

You have two options to run the demo.

* Option 1: run the demo end-to-end for all services

```bash
$ ./run.sh
```

* Option 2: step through it one service at a time

```bash
$ ./init.sh
$ ./broker.sh
$ ./schema-registry.sh
$ ./cleanup.sh
```

## Prerequisities

* [Confluent CLI](https://docs.confluent.io/current/cli/installing.html) installed on your machine, version `v0.119.0` or higher (note: as of CP 5.3, the Confluent CLI is a separate [download](https://docs.confluent.io/current/cli/installing.html)
