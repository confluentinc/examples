#!/bin/bash

##################################################
# Cleanup
##################################################

# Source library
. ../../../utils/helper.sh

check_env || exit 1
check_cli_v2 || exit 1


echo -e "\n# Cleanup"
rm /tmp/tokenKeyPair.pem
rm /tmp/tokenPublicKey.pem
rm /tmp/login.properties

confluent local destroy
