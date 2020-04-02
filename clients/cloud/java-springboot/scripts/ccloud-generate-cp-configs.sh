#!/bin/bash
#
# Copyright 2020 Confluent Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################
# Overview:
#
# This code reads a local Confluent Cloud configuration file
# and writes delta configuration files into ./delta_configs for
# Confluent Platform components and clients connecting to Confluent Cloud.
#
# Arguments:
#
#   1 (optional) - CONFIG_FILE, defaults to ~/.ccloud/config, (required if specifying SR_CONFIG_FILE)
#   2 (optional) - SR_CONFIG_FILE, defaults to CONFIG_FILE
#
# Example CONFIG_FILE at ~/.ccloud/config
#
#   $ cat $HOME/.ccloud/config
#
#   bootstrap.servers=<BROKER ENDPOINT>
#   ssl.endpoint.identification.algorithm=https
#   security.protocol=SASL_SSL
#   sasl.mechanism=PLAIN
#   sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username\="<API KEY>" password\="<API SECRET>";
#
# If you are using Confluent Cloud Schema Registry, add the following configuration parameters
# either to file above (arg 1 CONFIG_FILE) or to a separate file (arg 2 SR_CONFIG_FILE)
#
#   basic.auth.credentials.source=USER_INFO
#   schema.registry.basic.auth.user.info=<SR API KEY>:<SR API SECRET>
#   schema.registry.url=https://<SR ENDPOINT>
#
################################################################################

CONFIG_FILE=$1
if [[ -z "$CONFIG_FILE" ]]; then
  CONFIG_FILE=~/.ccloud/config
fi
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "File $CONFIG_FILE is not found.  Please create this properties file to connect to your Confluent Cloud cluster and then try again"
  exit 1
fi
echo "CONFIG_FILE: $CONFIG_FILE"

SR_CONFIG_FILE=$2
if [[ -z "$SR_CONFIG_FILE" ]]; then
  SR_CONFIG_FILE=$CONFIG_FILE
fi
if [[ ! -f "$SR_CONFIG_FILE" ]]; then
  echo "File $SR_CONFIG_FILE is not found.  Please create this properties file to connect to your Schema Registry and then try again"
  exit 1
fi
echo "SR_CONFIG_FILE: $SR_CONFIG_FILE"

# Set permissions
PERM=600
if ls --version 2>/dev/null | grep -q 'coreutils'; then
  # GNU binutils
  PERM=$(stat -c "%a" $CONFIG_FILE)
else
  # BSD
  PERM=$(stat -f "%OLp" $CONFIG_FILE)
fi
#echo "INFO: setting file permission to $PERM"

# Make destination
DEST="delta_configs"
mkdir -p $DEST

################################################################################
# Clean parameters from the Confluent Cloud configuration file
################################################################################
BOOTSTRAP_SERVERS=$(grep "^bootstrap.server" $CONFIG_FILE | awk -F'=' '{print $2;}')
BOOTSTRAP_SERVERS=${BOOTSTRAP_SERVERS/\\/}
SASL_JAAS_CONFIG=$(grep "^sasl.jaas.config" $CONFIG_FILE | cut -d'=' -f2-)
SASL_JAAS_CONFIG_PROPERTY_FORMAT=${SASL_JAAS_CONFIG/username\\=/username=}
SASL_JAAS_CONFIG_PROPERTY_FORMAT=${SASL_JAAS_CONFIG_PROPERTY_FORMAT/password\\=/password=}

#echo "bootstrap.servers: $BOOTSTRAP_SERVERS"
#echo "sasl.jaas.config: $SASL_JAAS_CONFIG"

BASIC_AUTH_CREDENTIALS_SOURCE=$(grep "^basic.auth.credentials.source" $SR_CONFIG_FILE | awk -F'=' '{print $2;}')
SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO=$(grep "^schema.registry.basic.auth.user.info" $SR_CONFIG_FILE | awk -F'=' '{print $2;}')
SCHEMA_REGISTRY_URL=$(grep "^schema.registry.url" $SR_CONFIG_FILE | awk -F'=' '{print $2;}')

#echo "basic.auth.credentials.source: $BASIC_AUTH_CREDENTIALS_SOURCE"
#echo "schema.registry.basic.auth.user.info: $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO"
#echo "schema.registry.url: $SCHEMA_REGISTRY_URL"

################################################################################
# ENV
################################################################################
ENV_CONFIG=$DEST/env.delta
# echo "$ENV_CONFIG"
rm -f $ENV_CONFIG

cat <<EOF >>$ENV_CONFIG
export BOOTSTRAP_SERVERS='$BOOTSTRAP_SERVERS'
export SASL_JAAS_CONFIG='$SASL_JAAS_CONFIG'
export SASL_JAAS_CONFIG_PROPERTY_FORMAT='$SASL_JAAS_CONFIG_PROPERTY_FORMAT'
export REPLICATOR_SASL_JAAS_CONFIG='$REPLICATOR_SASL_JAAS_CONFIG'
export BASIC_AUTH_CREDENTIALS_SOURCE=$BASIC_AUTH_CREDENTIALS_SOURCE
export SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO=$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO
export SCHEMA_REGISTRY_URL=$SCHEMA_REGISTRY_URL
EOF
chmod $PERM $ENV_CONFIG
