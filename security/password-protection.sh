#!/bin/bash


################################################################################
# Overview
################################################################################
#
# Demo the new Password Protection functionality
# using the updated Confluent CLI
#
# Documentation accompanying this tutorial:
#
#   <INSERT URL>
#
# Usage:
#
#   # Provide all arguments on command line
#   ./password-protection.sh
#
# Requirements:
#
#   - Confluent Platform 5.3 or higher (https://www.confluent.io/download/)
#   - Local install of the new Confluent CLI (v0.103.0 or above)
#   - `timeout` installed on your host
#   - `mvn` installed on your host
#
################################################################################

# Source library
. ../utils/helper.sh

check_cli_v2 || exit 1
check_timeout || exit 1
check_mvn || exit 1

##################################################
# Initialize parameters
##################################################
LOCAL_SECRETS_FILE=/tmp/local-secrets-file.txt
ORIGINAL_CONFIGURATION_FILE=$CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties 
CONFIGURATION_FILE=/tmp/connect-avro-distributed.properties
CONFIG=config.storage.topic
OUTPUT_FILE=/tmp/output.txt
rm -fr $LOCAL_SECRETS_FILE
rm -f $CONFIGURATION_FILE
rm -f $OUTPUT_FILE
unset CONFLUENT_SECURITY_MASTER_KEY

##################################################
# Generate the master key based on a passphrase
##################################################
OUTPUT=$(confluent secret master-key generate --passphrase @passphrase.txt --local-secrets-file $LOCAL_SECRETS_FILE)
if [[ $? != 0 ]]; then
  echo "Failed to create master-key. Please troubleshoot and run again"
  exit 1
fi
MASTER_KEY=$(echo "$OUTPUT" | grep '| Master Key' | awk '{print $5;}')
echo "MASTER_KEY: $MASTER_KEY"

# Export the master key
export CONFLUENT_SECURITY_MASTER_KEY=$MASTER_KEY

##################################################
# Encrypt a configuration file
# - configuration file is a copy of $CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties
# - configuration parameter is config.storage.topic
##################################################
cp $ORIGINAL_CONFIGURATION_FILE $CONFIGURATION_FILE

# Explicitly specify which configuration parameters should be encrypted
confluent secret file encrypt --local-secrets-file $LOCAL_SECRETS_FILE --remote-secrets-file $LOCAL_SECRETS_FILE --config-file $CONFIGURATION_FILE --config $CONFIG

##################################################
# Update the secret
##################################################
# Check the metadata again
grep "^$CONFIG" $CONFIGURATION_FILE
grep $CONFIG $LOCAL_SECRETS_FILE

# Updated the parameter value
confluent secret file update --local-secrets-file $LOCAL_SECRETS_FILE --remote-secrets-file $LOCAL_SECRETS_FILE --config-file $CONFIGURATION_FILE --config "${CONFIG}=newTopicName"

# Check the metadata again
grep "^$CONFIG" $CONFIGURATION_FILE
grep $CONFIG $LOCAL_SECRETS_FILE

##################################################
# Decrypt the file
##################################################
# Print the decrypted configuration values
confluent secret file decrypt --local-secrets-file $LOCAL_SECRETS_FILE --config-file $CONFIGURATION_FILE --output-file $OUTPUT_FILE
cat $OUTPUT_FILE

# Rotate datakey
confluent secret file rotate --data-key --local-secrets-file $LOCAL_SECRETS_FILE --passphrase @passphrase.txt

# Print the decrypted configuration values
confluent secret file decrypt --local-secrets-file $LOCAL_SECRETS_FILE --config-file $CONFIGURATION_FILE --output-file $OUTPUT_FILE
cat $OUTPUT_FILE

##################################################
# Cleanup
##################################################
rm -fr $LOCAL_SECRETS_FILE
rm -f $CONFIGURATION_FILE
rm -f $OUTPUT_FILE
unset CONFLUENT_SECURITY_MASTER_KEY
