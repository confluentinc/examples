.. _ccloud-cli-tutorial-overview:

Tutorial: |ccloud| CLI
=======================

Overview
--------

This tutorial shows you how to use the `Confluent Cloud CLI
<https://docs.confluent.io/ccloud-cli/current/install.html>`__ to interact with
your `Confluent Cloud <https://confluent.cloud/login>`__ cluster. It uses real
resources in |ccloud|, and it creates and deletes topics, service accounts,
credentials, and ACLs. Following the workflow in this tutorial, you accomplish
the following steps:

-  `Create a new Confluent Cloud environment`_
-  `Create a new Confluent Cloud cluster`_
-  `Create a new API key/secret pair for user`_
-  `Produce and consume records with Confluent Cloud CLI`_
-  `Create a new service account with an API key/secret pair`_
-  `Run a Java producer without ACLs`_
-  `Run a Java producer with ACLs`_
-  `Run a Java producer with a prefixed ACL`_
-  `Run a fully managed Confluent Cloud connector`_
-  `Run a Java consumer with a Wildcard ACL`_
-  `Monitor producers and consumers`_
-  `Clean up Confluent Cloud resources`_

Prerequisites
-------------

-  Access to `Confluent Cloud <https://confluent.cloud/login>`__.

-  Local `install of Confluent Cloud CLI
   <https://docs.confluent.io/ccloud-cli/current/install.html>`__ (v1.21.0 or later)

-  .. include:: ../../ccloud/docs/includes/prereq_timeout.rst

-  `mvn <https://maven.apache.org/install.html>`__ installed on your host

-  `jq <https://github.com/stedolan/jq/wiki/Installation>`__ installed on your host

-  `docker <https://docs.docker.com/get-docker/>`__ installed on your host
