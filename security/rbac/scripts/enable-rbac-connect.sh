#!/bin/bash


################################################################################
# Overview
################################################################################
#
################################################################################

# Source library
. ../../../utils/helper.sh
. ./rbac_lib.sh

check_env || exit 1
check_cli_v2 || exit 1
check_jq || exit 1

##################################################
# Initialize
##################################################

. ../config/local-demo.cfg
ORIGINAL_CONFIGS_DIR=../original_configs
DELTA_CONFIGS_DIR=../delta_configs
FILENAME=connect-avro-distributed.properties
create_temp_configs $CONFLUENT_HOME/etc/schema-registry/$FILENAME $ORIGINAL_CONFIGS_DIR/$FILENAME $DELTA_CONFIGS_DIR/${FILENAME}.delta

# Log in to Metadata Server (MDS)
login_mds $MDS

##################################################
# Administrative Functions
##################################################

echo -e "\n# Bring up Connect"
confluent local start connect

# Check for errors
sleep 10
grep ERROR `confluent local current | tail -1`/connect/connect.stdout

# Get the Kafka cluster id
get_cluster_id_kafka


##################################################
# Connect client functions
##################################################


##################################################
# Cleanup
##################################################

SAVE_CONFIGS_DIR=../rbac_configs
restore_configs $CONFLUENT_HOME/etc/schema-registry/${FILENAME} $ORIGINAL_CONFIGS_DIR/${FILENAME} $SAVE_CONFIGS_DIR/${FILENAME}.rbac
