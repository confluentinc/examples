#!/bin/bash

##################################################
# Cleanup
##################################################

# Source library
source ../../../utils/helper.sh

check_env || exit 1
validate_version_confluent_cli_v2 || exit 1


echo -e "\n# Cleanup"
rm -f /tmp/tokenKeyPair.pem || true
rm -f /tmp/tokenPublicKey.pem || true
rm -f /tmp/login.properties || true

confluent local destroy

# Clean up each individual properties file
for propfile in $CONFLUENT_HOME/etc/kafka/server.properties $CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties $CONFLUENT_HOME/etc/confluent-control-center/control-center-dev.properties $CONFLUENT_HOME/etc/ksqldb/ksql-server.properties $CONFLUENT_HOME/etc/kafka-rest/kafka-rest.properties $CONFLUENT_HOME/etc/schema-registry/schema-registry.properties; do
  echo "Removing RBAC demo configurations from $propfile"
  TMP_FILE=`mktemp`
  sed -e '/RBAC demo start/,/RBAC demo end/d' $propfile > $TMP_FILE
  mv $TMP_FILE $propfile
done
