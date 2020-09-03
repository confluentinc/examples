
.. _secret-protection-tutorial:

Tutorial: Secret Protection
===========================

Overview
--------

|cp| secrets allow you to store and manage sensitive information, such as
passwords and API tokens. Instead of storing passwords or other sensitive data
as cleartext, you can encrypt the data within a configuration file itself.


Prerequisites
~~~~~~~~~~~~~

#. `Download <https://www.confluent.io/download/>`__ |cp| |release|


Setup
-----

#. Clone the Confluent examples repository.

   .. code:: bash

       git clone https://github.com/confluentinc/examples.git

#. Navigate to the ``examples/security/secret-protection`` directory and switch
   to the |cp| release branch:

   .. codewithvars:: bash

       cd examples/security/secret-protection
       git checkout |release_post_branch|

#. If you want to manually step through the tutorial, which is advised for new
   users who want to gain familiarity with secrets, skip ahead to the next
   section. Alternatively, you can run the full solution end-to-end with
   :devx-examples:`this automated
   script|security/secret-protection/demo-secret-protection.sh`.

   .. code:: bash

       ./demo-secret-protection.sh

Run Tutorial
------------

Generating the master encryption key based on a passphrase
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Decide on a master encryption key passphrase.  Your passphrase should be
   longer than the usual password. Choose a phrase you can remember as a string of
   words.

#. Write the passphrase into a local file (e.g. ``/path/to/passphrase.txt``)
   which will be passed into the CLI. Writing to a file avoids logging history
   showing the passphrase.
   
#. Choose the location where the secrets file will reside on your local host.
   The location shouldn't be where the |cp| services run. The secrets file will
   contain encrypted secrets for the master encryption key, data encryption key,
   and configuration parameters, along with their metadata, such as which cipher
   was used for encryption.

#. Generate the master encryption key by running the following command:

   .. code-block:: text

      # passphrase: /path/to/passphrase.txt
      # local-secrets-file: /path/to/secrets.txt

      confluent secret master-key generate --local-secrets-file /path/to/secrets.txt --passphrase @/path/to/passphrase.txt

   You should see:

   .. code-block:: text

      Save the master key. It cannot be retrieved later.
      +------------+----------------------------------------------+
      | Master Key | Nf1IL2bmqRdEz2DO//gX2C+4PjF5j8hGXYSu9Na9bao= |
      +------------+----------------------------------------------+

#. Save the master key somewhere safe on your computer.

#. Export the key into the environment on the local host and every other host
   that will have a configuration file with secret protection. For example:

   .. code-block:: text

      export CONFLUENT_SECURITY_MASTER_KEY=Nf1IL2bmqRdEz2DO//gX2C+4PjF5j8hGXYSu9Na9bao=

#. (Optional) To protect the previous environment variable in a production host, you can set
   the master encryption key at the process level instead of the global machine
   level. For example, you could set it in the ``systemd`` overrides for executed
   processes, restricting the environment directives file to root-only access.


Encrypting the value of a configuration parameter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In this section, you will encrypt a configuration parameter available in the configuration file example that
ships with |cp|.

To encrypt the parameter ``config.storage.topic`` in
``$CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties``,
complete the following steps:

#. Make a backup of the file
   ``$CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties``,
   because the CLI currently does in-place modification on the original file.

#. Select the exact path where the secrets file will reside on the remote hosts
   where the |cp| services run, e.g. ``/path/to/secrets-remote.txt``.

#. View the value before encryption.

   .. code-block:: bash

      grep "config\.storage\.topic" connect-avro-distributed.properties

   Your output should resemble:

   .. code-block:: text

      config.storage.topic=connect-configs

#. Encrypt the field:

   .. code-block:: text

         # remote-secrets-file: /path/to/secrets-remote.txt
         confluent secret file encrypt --local-secrets-file /path/to/secrets.txt --remote-secrets-file /path/to/secrets-remote.txt --config-file connect-avro-distributed.properties --config config.storage.topic

#. View the value after encryption.

   .. code-block:: bash

      grep "config\.storage\.topic" connect-avro-distributed.properties

   Your output should resemble:

   .. code-block:: text

      config.storage.topic = ${securepass:/path/to/secrets-remote.txt:connect-avro-distributed.properties/config.storage.topic}

#. Validate that the configuration parameter ``config.storage.topic`` setting
   was changed from ``connect-configs`` to
   ``${securepass:/path/to/secrets-remote.txt:connect-avro-distributed.properties/config.storage.topic}``.
   This is a tuple that directs the service to use to look up the encrypted
   value of the file/parameter pair
   ``connect-avro-distributed.properties/config.storage.topic`` from the secrets
   file ``/path/to/secrets-remote.txt``.

#. View the contents of the local secrets file ``/path/to/secrets.txt``, which
   should contain the encrypted secret for this file or parameter pair along with
   the metadata (for example, which cipher was used for encryption):

   .. code-block:: bash

      cat /path/to/secrets.txt

   You should see:

   .. code-block:: text

      ...
      connect-avro-distributed.properties/config.storage.topic = ENC[AES/CBC/PKCS5Padding,data:CUpHh5lRDfIfqaL49V3iGw==,iv:vPBmPkctA+yYGVQuOFmQJw==,type:str]


Decrypting the value of a configuration parameter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can also decrypt the value of a configuration parameter into a file by
completing the following steps:

#. Run the following command to decrypt the value into a file:

   .. code-block:: bash

      confluent secret file decrypt --local-secrets-file /path/to/secrets.txt --config-file connect-avro-distributed.properties --output-file decrypted.txt

#. View the file:

   .. code-block:: bash

      cat decrypted.txt

   You should see the following output:

   .. code-block:: bash

      config.storage.topic = connect-configs


Updating the value of the configuration parameter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You may need to update secrets on a regular basis to ensure the secrets don't
get stale. The configuration parameter ``config.storage.topic`` was originally
set to ``connect-configs``. If you must change this value in the future, you can
update it using the CLI.

#. In the following CLI, pass in a file ``/path/to/updated-config-and-value`` that
   has written ``config.storage.topic=newTopicName`` to avoid logging history
   showing the new value.

   .. code-block:: bash

      confluent secret file update --local-secrets-file /path/to/secrets.txt --remote-secrets-file /path/to/secrets-remote.txt --config-file connect-avro-distributed.properties --config @/path/to/updated-config-and-value

#. The configuration file ``connect-avro-distributed.properties`` doesn't change
   because it’s a pointer to the secrets file, but the secrets file has a new value
   for the encrypted value for this file/parameter pair.  When running the following command:

   .. code-block:: bash

      cat /path/to/secrets.txt

   You should see:

   .. code-block:: bash

      ...
      connect-avro-distributed.properties/config.storage.topic = ENC[AES/CBC/PKCS5Padding,data:CblF3k1ieNkFJzlJ51qAAA==,iv:dnZwEAm1rpLyf48pvy/T6w==,type:str]


Verify on |ak| cluster
~~~~~~~~~~~~~~~~~~~~~~

Run |ak| and start the
modified connect worker with the encrypted value of
``config.storage.topic=newTopicName`` by completing the following steps:

#. Start |zk| and a |ak| broker:

   .. code-block:: bash

      confluent local start kafka

#. Run the modified |kconnect| worker:

   .. code-block:: bash

      connect-distributed connect-avro-distributed.properties > connect.stdout 2>&1 &

#. List the topics:

   .. code-block:: text

      kafka-topics --bootstrap-server localhost:9092 --list
      __confluent.support.metrics
      __consumer_offsets
      _confluent-metrics
      connect-offsets
      connect-statuses
      newTopicName   <<<<<<<

Going to production
~~~~~~~~~~~~~~~~~~~

So far you've learned how to create the master encryption key and encrypt
secrets in the configuration files. Confluent recommends you operationalize the
workflow by augmenting your orchestration tooling to distribute everything you
need for secret protection to work to the destination hosts. These hosts may
include |ak| brokers, |kconnect| workers, |sr-long| instances, |ksql-cloud|
servers, |c3|, and more–any service using password encryption. The CLI is
flexible to accommodate whatever secret distribution model you prefer. You can
either perform the secret generation and configuration modification on each
destination host directly, or do it all on a single host and then distribute the
encrypted secrets to the destination hosts. Here are four required tasks:

#. Export the master encryption key into the environment on every host
   that will have a configuration file with secret protection.

#. Distribute the secrets file: copy the secrets file ``/path/to/secrets.txt``
   from the local host on which you have been working to
   ``/path/to/secrets-remote.txt`` on the destination hosts.

#. Propagate the necessary configuration file changes: update the
   configuration file on all hosts so that the configuration parameter now has
   the tuple for secrets.

#. Restart the services if they were already running.

You may also have a requirement to rotate the master encryption key or data
encryption key on a regular basis. You can do either of these with the CLI. To
rotate the data encryption key only, run the following command:

.. code-block:: bash

   confluent secret file rotate --data-key --local-secrets-file /path/to/secrets.txt --passphrase @/path/to/passphrase.txt

