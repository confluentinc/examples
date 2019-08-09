#!/bin/bash
#
# Copyright 2016 Confluent Inc.
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
# This code reads the Confluent Cloud configuration in $HOME/.ccloud/config
# and writes the ENV variables used by Docker Compose to a file called 'delta_configs/env.delta'
#
# Reference: https://github.com/confluentinc/examples/blob/5.1.2-post/ccloud/ccloud-generate-cp-configs.sh
#
###############################################################################

set -eu

# Confluent Cloud configuration
CCLOUD_CONFIG=$HOME/.ccloud/config
if [[ ! -f $CCLOUD_CONFIG ]]; then
  echo "'ccloud' is not initialized. Run 'ccloud init' and try again"
  exit 1
fi
PERM=$(stat -c "%a" $HOME/.ccloud/config)


################################################################################
# Specify configuration file for Confluent Schema Registry
################################################################################
SR_CONFIG_FILE=schema_registry_docker.config
if [[ $# -ne 0 ]] && [[ ! -z "$1" ]]; then
  SR_CONFIG_FILE=$1
fi
# Make destination
DEST="delta_configs"
mkdir -p $DEST


################################################################################
# Glean parameters from the Confluent Cloud configuration file
################################################################################
BOOTSTRAP_SERVERS=$( grep "^bootstrap.server" $CCLOUD_CONFIG | awk -F'=' '{print $2;}' )
BOOTSTRAP_SERVERS=${BOOTSTRAP_SERVERS/\\/}
SASL_JAAS_CONFIG=$( grep "^sasl.jaas.config" $CCLOUD_CONFIG | cut -d'=' -f2- )
CLOUD_KEY=$( echo $SASL_JAAS_CONFIG | awk '{print $3}' | awk -F'"' '$0=$2' )
CLOUD_SECRET=$( echo $SASL_JAAS_CONFIG | awk '{print $4}' | awk -F'"' '$0=$2' )
#echo "bootstrap.servers: $BOOTSTRAP_SERVERS"
#echo "sasl.jaas.config: $SASL_JAAS_CONFIG"
#echo "key: $CLOUD_KEY"
#echo "secret: $CLOUD_SECRET"

BASIC_AUTH_CREDENTIALS_SOURCE=$( grep "^basic.auth.credentials.source" $SR_CONFIG_FILE | awk -F'=' '{print $2;}' )
SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO=$( grep "^schema.registry.basic.auth.user.info" $SR_CONFIG_FILE | awk -F'=' '{print $2;}' )
SCHEMA_REGISTRY_URL=$( grep "^schema.registry.url" $SR_CONFIG_FILE | awk -F'=' '{print $2;}' )
#echo "basic.auth.credentials.source: $BASIC_AUTH_CREDENTIALS_SOURCE"
#echo "schema.registry.basic.auth.user.info: $SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO"
#echo "schema.registry.url: $SCHEMA_REGISTRY_URL"

REPLICATOR_SASL_JAAS_CONFIG=$SASL_JAAS_CONFIG
REPLICATOR_SASL_JAAS_CONFIG=${REPLICATOR_SASL_JAAS_CONFIG//\\=/=}
REPLICATOR_SASL_JAAS_CONFIG=${REPLICATOR_SASL_JAAS_CONFIG//\"/\\\"}

ENV_CONFIG=$DEST/env.delta
echo "$ENV_CONFIG"
rm -f $ENV_CONFIG

cat <<EOF >> $ENV_CONFIG
export BOOTSTRAP_SERVERS='$BOOTSTRAP_SERVERS'
export SASL_JAAS_CONFIG='$SASL_JAAS_CONFIG'
export REPLICATOR_SASL_JAAS_CONFIG='$REPLICATOR_SASL_JAAS_CONFIG'
export BASIC_AUTH_CREDENTIALS_SOURCE=$BASIC_AUTH_CREDENTIALS_SOURCE
export SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO=$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO
export SCHEMA_REGISTRY_URL=$SCHEMA_REGISTRY_URL
EOF
chmod $PERM $ENV_CONFIG
