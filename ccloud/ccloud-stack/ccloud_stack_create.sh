#!/bin/bash

#########################################
# This script uses real Confluent Cloud resources.
# To avoid unexpected charges, carefully evaluate the cost of resources before launching the script and ensure all resources are destroyed after you are done running it.
#########################################


# Source library
source ../../utils/helper.sh
source ../../utils/ccloud_library.sh

ccloud::prompt_continue_ccloud_demo || exit 1

ccloud::validate_version_cli $CLI_MIN_VERSION || exit 1
check_jq || exit 1
ccloud::validate_logged_in_cli || exit 1

enable_ksqldb=false
read -p "Do you also want to create a Confluent Cloud ksqlDB app (hourly charges may apply)? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  enable_ksqldb=true
fi

if [[ -z "$ENVIRONMENT" ]]; then
  STMT=""
else
  STMT="PRESERVE_ENVIRONMENT=true"
fi

export EXAMPLE="ccloud-stack-script"

echo
ccloud::create_ccloud_stack $enable_ksqldb || exit 1

echo
echo "Validating..."
SERVICE_ACCOUNT_ID=$(ccloud:get_service_account_from_current_cluster_name)
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
ccloud::validate_ccloud_config $CONFIG_FILE || exit 1
ccloud::generate_configs $CONFIG_FILE > /dev/null
source delta_configs/env.delta

if $enable_ksqldb ; then
  MAX_WAIT=720
  echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud ksqlDB cluster to be UP"
  retry $MAX_WAIT ccloud::validate_ccloud_ksqldb_endpoint_ready $KSQLDB_ENDPOINT || exit 1
fi

ccloud::validate_ccloud_stack_up $CLOUD_KEY $CONFIG_FILE $enable_ksqldb || exit 1

echo
echo "ACLs in this cluster:"
confluent kafka acl list

echo
echo "Local client configuration file written to $CONFIG_FILE"
echo

echo
echo "To destroy this Confluent Cloud stack run ->"
echo "    $STMT ./ccloud_stack_destroy.sh $CONFIG_FILE"
echo

echo
ENVIRONMENT=$(ccloud::get_environment_id_from_service_id $SERVICE_ACCOUNT_ID)
echo "Tip: 'confluent' CLI has been set to the new environment $ENVIRONMENT"
