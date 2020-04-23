#!/bin/bash


################################################################################
# Overview
################################################################################
#
# Demo Secret Protection functionality using the updated Confluent CLI
#
# Documentation accompanying this tutorial: README.adoc
#
# Usage:
#
#   # Provide all arguments on command line
#   ./demo-secret-protection.sh
#
# Requirements:
#
#   - Confluent Platform 5.4 or higher (https://www.confluent.io/download/)
#   - Local install of the new Confluent CLI (v0.200.0 or above)
#
################################################################################


function cleanup() {
  rm -f $LOCAL_SECRETS_FILE
  rm -f $REMOTE_SECRETS_FILE
  rm -f $MODIFIED_CONFIGURATION_FILE
  rm -f $OUTPUT_FILE
  unset CONFLUENT_SECURITY_MASTER_KEY

  return 0
}


# Source library
. ../../utils/helper.sh

check_env || exit 1
check_running_cp ${CONFLUENT} || exit
check_cli_v2 || exit

##################################################
# Initialize parameters
##################################################
LOCAL_SECRETS_FILE=/tmp/secrets-local.txt
REMOTE_SECRETS_FILE=/tmp/secrets-remote.txt
ORIGINAL_CONFIGURATION_FILE=$CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties 
MODIFIED_CONFIGURATION_FILE=/tmp/connect-avro-distributed.properties
CONFIG=config.storage.topic
OUTPUT_FILE=/tmp/output.txt
cleanup

##################################################
# Generate the master key based on a passphrase
##################################################
echo -e "\n----- Generate the master key -----"
echo -e "\nGenerate the master key based on a passphrase"
echo -e "confluent secret master-key generate --passphrase @etc/passphrase.txt --local-secrets-file $LOCAL_SECRETS_FILE"
OUTPUT=$(confluent secret master-key generate --passphrase @etc/passphrase.txt --local-secrets-file $LOCAL_SECRETS_FILE)
if [[ $? != 0 ]]; then
  echo "Failed to create master-key. Please troubleshoot and run again"
  exit 1
fi
MASTER_KEY=$(echo "$OUTPUT" | grep '| Master Key' | awk '{print $5;}')
#echo "MASTER_KEY: $MASTER_KEY"

# Export the master key
echo -e "\nExport the master key"
echo -e "export CONFLUENT_SECURITY_MASTER_KEY=$MASTER_KEY"
export CONFLUENT_SECURITY_MASTER_KEY=$MASTER_KEY

##################################################
# Encrypt the value of a configuration parameter
# - configuration file is a copy of $CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties
# - configuration parameter is config.storage.topic
##################################################
cp $ORIGINAL_CONFIGURATION_FILE $MODIFIED_CONFIGURATION_FILE

echo -e "\n----- Encrypt configuration parameter -----"
echo -e "\nvalue of $CONFIG in $MODIFIED_CONFIGURATION_FILE"
grep "^$CONFIG" $MODIFIED_CONFIGURATION_FILE

# Explicitly specify which configuration parameters should be encrypted
echo -e "\nEncrypt the configuration parameter $CONFIG in configuration file $MODIFIED_CONFIGURATION_FILE"
echo -e "confluent secret file encrypt --local-secrets-file $LOCAL_SECRETS_FILE --remote-secrets-file $REMOTE_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --config $CONFIG"
confluent secret file encrypt --local-secrets-file $LOCAL_SECRETS_FILE --remote-secrets-file $REMOTE_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --config $CONFIG

echo -e "\nvalue of $CONFIG in $MODIFIED_CONFIGURATION_FILE"
grep "^$CONFIG" $MODIFIED_CONFIGURATION_FILE


##################################################
# Update the value of the configuration parameter
##################################################
# Check the secrets

echo -e "\n----- Update the value of the configuration parameter -----"
echo -e "\nvalue of $CONFIG in $MODIFIED_CONFIGURATION_FILE"
grep "^$CONFIG" $MODIFIED_CONFIGURATION_FILE
echo -e "\nvalue of $CONFIG in $LOCAL_SECRETS_FILE"
grep $CONFIG $LOCAL_SECRETS_FILE

# Update the parameter value
echo -e "\nUpdate the configuration parameter $CONFIG to a new value"
echo -e "confluent secret file update --local-secrets-file $LOCAL_SECRETS_FILE --remote-secrets-file $REMOTE_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --config @etc/new-config-value.txt"
confluent secret file update --local-secrets-file $LOCAL_SECRETS_FILE --remote-secrets-file $REMOTE_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --config @etc/new-config-value.txt

# Check the secrets again
echo -e "\nvalue of $CONFIG in $MODIFIED_CONFIGURATION_FILE (this has not changed)"
grep "^$CONFIG" $MODIFIED_CONFIGURATION_FILE
echo -e "\nvalue of $CONFIG in $LOCAL_SECRETS_FILE (this has changed)"
grep $CONFIG $LOCAL_SECRETS_FILE

##################################################
# Decrypt the file
##################################################

# Print the decrypted configuration values
echo -e "\n----- Rotate the data key and decrypt the configuration parameter -----"
echo -e "\nDecrypt the secret"
echo -e "confluent secret file decrypt --local-secrets-file $LOCAL_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --output-file $OUTPUT_FILE"
confluent secret file decrypt --local-secrets-file $LOCAL_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --output-file $OUTPUT_FILE
echo -e "\ndecrypted value:"
cat $OUTPUT_FILE

# Rotate datakey
echo -e "\nRotate the datakey"
echo -e "confluent secret file rotate --data-key --local-secrets-file $LOCAL_SECRETS_FILE --passphrase @etc/passphrase.txt"
confluent secret file rotate --data-key --local-secrets-file $LOCAL_SECRETS_FILE --passphrase @etc/passphrase.txt

# Print the decrypted configuration values
echo -e "\nDecrypt the secret after the datakey has been rotated"
echo -e "confluent secret file decrypt --local-secrets-file $LOCAL_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --output-file $OUTPUT_FILE"
confluent secret file decrypt --local-secrets-file $LOCAL_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --output-file $OUTPUT_FILE
echo -e "\ndecrypted value:"
cat $OUTPUT_FILE

##################################################
# End
##################################################
echo -e "\n----- View files -----\n"
echo -e "LOCAL_SECRETS_FILE: $LOCAL_SECRETS_FILE"
echo -e "ORIGINAL_CONFIGURATION_FILE: $ORIGINAL_CONFIGURATION_FILE"
echo -e "MODIFIED_CONFIGURATION_FILE: $MODIFIED_CONFIGURATION_FILE"

echo -e "\n----- diff files -----\n"
echo "diff -w $ORIGINAL_CONFIGURATION_FILE $MODIFIED_CONFIGURATION_FILE"
diff -w $ORIGINAL_CONFIGURATION_FILE $MODIFIED_CONFIGURATION_FILE
