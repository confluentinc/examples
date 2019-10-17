# Replicator Schema Translation Demo

## Overview

Confluent Replicator features the ability to translate entries from a source Schema Registry to a destination Schema Registry.

This demo provides a docker-compose environment with source and destination Schema Registries in which schemas are translated. In this demo, you create an entry in the source Schema Registry and translate it to the destination.

The `scripts` directory provides examples of the operations that you must perform to prepare for the translation, as well as JSON Replicator configurations required.

The demo performs the following migration steps:

1. Create a subject in the source Schema Registry.
2. Prepare for schema translation.
3. Execute Replicator to perform migration.
4. Post-translation Schema Registry configuration. 

## Prerequisites

This demo has been validated with:

-  Docker 19.03.2
-  Docker-compose 1.24.1
-  Java version 1.8.0_162
-  MacOS 10.12

These demos are memory intensive and Docker must be tuned accordingly. In Docker's advanced settings, increase the memory dedicated to Docker to at least 8GB (the default is 2GB).

# Running the demo

You can find the documentation for running this demo at [https://docs.confluent.io/current/tutorials/examples/ccloud/docs/index.html](https://docs.confluent.io/current/tutorials/examples/replicator-schema-translation/docs/index.html)
