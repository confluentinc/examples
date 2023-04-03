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

# Running the demo

You can find the documentation for running this demo at [https://docs.confluent.io/platform/current/tutorials/examples/replicator-schema-translation/docs/index.html](https://docs.confluent.io/platform/current/tutorials/examples/replicator-schema-translation/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.replicator-schema-translation)
