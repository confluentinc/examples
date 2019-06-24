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
# Generate the master key based on a passphrase
##################################################
LOCAL_SECRETS_FILE=/tmp/local-secrets-file.txt

rm -f $LOCAL_SECRETS_FILE
unset CONFLUENT_SECURITY_MASTER_KEY
rm -f $CONFIGURATION_FILE

OUTPUT=$(confluent secret master-key generate --passphrase @passphrase.txt --local-secrets-file $LOCAL_SECRETS_FILE)
if [[ $? != 0 ]]; then
  echo "Failed to create master-key. Please troubleshoot and run again"
  exit 1
fi
MASTER_KEY=$(echo "$OUTPUT" | grep '| Master Key' | awk '{print $5;}')
#echo "MASTER_KEY: $MASTER_KEY"

# Export the master key
export CONFLUENT_SECURITY_MASTER_KEY=$MASTER_KEY

##################################################
# Encrypt existing configuration file
##################################################
ORIGINAL_CONFIGURATION_FILE=docker-compose.yml.orig
CONFIGURATION_FILE=docker-compose.yml.working
cp $ORIGINAL_CONFIGURATION_FILE $CONFIGURATION_FILE
confluent secret file encrypt --config-file $CONFIGURATION_FILE --local-secrets-file $LOCAL_SECRETS_FILE --remote-secrets-file $LOCAL_SECRETS_FILE

##################################################
# Cleanup
##################################################
rm -fr $LOCAL_SECRETS_FILE
unset CONFLUENT_SECURITY_MASTER_KEY
#rm -f $CONFIGURATION_FILE
