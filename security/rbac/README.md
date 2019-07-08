![image](../../images/confluent-logo-300-2.png)

# Overview

This demo showcases the [Role Based Access Control (RBAC)](https://docs.confluent.io/current/security/rbac/index.html) functionality in Confluent Platform. It is mostly for reference to see a workflow using the new RBAC feature across the services in Confluent Platform.

## Notes

* For simplicity, this demo does not require the use of LDAP. Instead it uses the Hash Login service with users/passwords defined in the `login.properties` file.

# Run the demo

1. Change directory into the `scripts` folder:

```bash
$ cd scripts
```

2. Install the [Confluent CLI](https://docs.confluent.io/current/cli/installing.html). It must be installed on your machine, version `v0.119.0` or higher (note: as of CP 5.3, the Confluent CLI is a separate [download](https://docs.confluent.io/current/cli/installing.html)

3. You have two options to run the demo.

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
